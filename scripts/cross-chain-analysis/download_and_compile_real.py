#!/usr/bin/env python3
"""
Download verified source code + compiler version for every address in the
Smartaxe "real" dataset, compile it locally with the exact solc version, and
emit bytecode / ABI / AST-derived modifiers per address.

Why source instead of plain bytecode: the cross-chain Access Control
Incompleteness checker needs function *modifiers*, which only exist in the
compiler AST. Etherscan's `getabi` does not return them, so we must recompile
from source and decorate the ABI with modifiers extracted from the AST.

For proxy contracts (Etherscan Proxy=1) we follow the Implementation address and
compile the implementation's source instead.

Output layout (per address):
    datasets/cross-chain/smartaxe/real/<address>/
    ├── source-code/   .sol files (subdir paths preserved)
    ├── json/          solc standard-json output
    ├── bytecode/<address>.bytecode   0x-prefixed deployed runtime bytecode
    ├── abi/<address>.abi             ABI decorated with modifiers
    └── metadata.json                 is_proxy, impl address+url, compiler version

Usage:
    python3 download_and_compile_real.py                 # whole dataset
    python3 download_and_compile_real.py --address 0x..  # single address (repeatable)
    python3 download_and_compile_real.py --limit 5       # first N addresses
    python3 download_and_compile_real.py --force         # recompile even if present
"""

import argparse
import csv
import json
import os
import re
import subprocess
import time
import urllib.parse
import urllib.request

from tqdm import tqdm

# --- paths -------------------------------------------------------------------

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, "..", ".."))
REAL_DIR = os.path.join(REPO_ROOT, "datasets", "cross-chain", "smartaxe", "real")
ENV_FILE = os.path.join(REPO_ROOT, ".env")
FAILURES_CSV = os.path.join(REAL_DIR, "_failures.csv")

ETHERSCAN_URL = "https://api.etherscan.io/v2/api"
CHAIN_ID = "1"
REQUEST_THROTTLE_S = 0.25
ZERO_ADDRESS = "0x0000000000000000000000000000000000000000"

ADDRESS_RE = re.compile(r"^0x[a-fA-F0-9]{40}$")


# --- AST modifier helpers (copied from scripts/compile-smart-contracts.py) ----
# The compile script lives in a hyphenated file that cannot be imported as a
# module, so these two helpers are duplicated here (the codebase already
# duplicates helpers across scripts).

def collect_modifiers_from_ast(data):
    """Build a map: contract -> function name -> list of modifier names from AST."""
    modifiers = {}

    def walk(node, current_contract=None):
        if isinstance(node, dict):
            if node.get("nodeType") == "ContractDefinition":
                current_contract = node.get("name")
                modifiers.setdefault(current_contract, {})

            if node.get("nodeType") == "FunctionDefinition" and node.get("kind") == "function":
                fn_name = node.get("name")
                contract_entry = modifiers.setdefault(current_contract, {})
                contract_entry.setdefault(fn_name, [])

                for mod in node.get("modifiers", []):
                    if not isinstance(mod, dict):
                        continue
                    mod_name = None
                    mod_id = mod.get("modifierName")
                    if isinstance(mod_id, dict):
                        mod_name = mod_id.get("name")
                    elif isinstance(mod_id, str):
                        mod_name = mod_id
                    if mod_name:
                        contract_entry[fn_name].append(mod_name)

            for value in node.values():
                walk(value, current_contract)

        elif isinstance(node, list):
            for item in node:
                walk(item, current_contract)

    roots = []
    for src_data in data.get("sources", {}).values():
        if isinstance(src_data, dict):
            ast_node = src_data.get("ast") or src_data.get("AST")
            if ast_node:
                roots.append(ast_node)

    if data.get("ast"):
        roots.append(data.get("ast"))

    for root in roots:
        walk(root, None)

    return modifiers


def attach_modifiers_to_abi(contract_name, abi, modifiers_map):
    contract_key = contract_name.split(":")[-1]
    functions_mods = modifiers_map.get(contract_key, {})

    if isinstance(abi, str):
        try:
            abi = json.loads(abi)
        except json.JSONDecodeError:
            return abi

    if not isinstance(abi, list):
        return abi

    for entry in abi:
        if not isinstance(entry, dict):
            continue
        if entry.get("type") != "function":
            continue
        fn_name = entry.get("name")
        entry["modifiers"] = functions_mods.get(fn_name, [])

    return abi


# --- Etherscan ----------------------------------------------------------------

def load_api_key():
    """Read ETHERSCAN_API_KEY from .env (no extra dependency)."""
    if os.path.exists(ENV_FILE):
        with open(ENV_FILE, "r") as f:
            for line in f:
                line = line.strip()
                if line.startswith("ETHERSCAN_API_KEY="):
                    return line.split("=", 1)[1].strip()
    key = os.environ.get("ETHERSCAN_API_KEY")
    if key:
        return key
    raise RuntimeError("ETHERSCAN_API_KEY not found in .env or environment.")


def getsourcecode(address, api_key):
    """Call Etherscan v2 getsourcecode; return the first result dict or None."""
    params = urllib.parse.urlencode({
        "chainId": CHAIN_ID,
        "module": "contract",
        "action": "getsourcecode",
        "address": address,
        "apikey": api_key,
    })
    url = f"{ETHERSCAN_URL}?{params}"
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=30) as resp:
        payload = json.load(resp)

    if str(payload.get("status")) == "0" and not isinstance(payload.get("result"), list):
        # NOTOK / rate limit / invalid key
        return None
    result = payload.get("result")
    if not isinstance(result, list) or not result:
        return None
    return result[0]


# --- source parsing -----------------------------------------------------------

def parse_compiler_version(raw):
    """'v0.8.17+commit.8df45f5f' -> '0.8.17'."""
    if not raw:
        return None
    raw = raw.strip()
    if raw.startswith("v"):
        raw = raw[1:]
    return raw.split("+", 1)[0].strip()


def parse_sources(result):
    """
    Return (sources, settings) where sources maps relative path -> content.

    Handles the three Etherscan SourceCode encodings:
      1. double-brace standard-json: {{ "language":..., "sources": {...}, "settings": {...} }}
      2. single-brace multi-file:    { "<file>.sol": {"content": ...} }
      3. raw single-file Solidity source.
    """
    raw = result.get("SourceCode") or ""
    contract_name = result.get("ContractName") or "Contract"

    raw_stripped = raw.strip()

    # Format 1: standard-json wrapped in an extra brace pair.
    if raw_stripped.startswith("{{") and raw_stripped.endswith("}}"):
        inner = raw_stripped[1:-1]
        obj = json.loads(inner)
        sources = {}
        for path, entry in obj.get("sources", {}).items():
            content = entry.get("content") if isinstance(entry, dict) else entry
            if content is not None:
                sources[path] = content
        return sources, obj.get("settings", {})

    # Format 2: a JSON object mapping file path -> {"content": ...} (or standard-json
    # without the extra brace pair).
    if raw_stripped.startswith("{"):
        try:
            obj = json.loads(raw_stripped)
        except json.JSONDecodeError:
            obj = None
        if isinstance(obj, dict):
            if "sources" in obj and isinstance(obj["sources"], dict):
                sources = {}
                for path, entry in obj["sources"].items():
                    content = entry.get("content") if isinstance(entry, dict) else entry
                    if content is not None:
                        sources[path] = content
                return sources, obj.get("settings", {})
            # plain {path: {content}} map
            sources = {}
            for path, entry in obj.items():
                if isinstance(entry, dict) and "content" in entry:
                    sources[path] = entry["content"]
            if sources:
                return sources, {}

    # Format 3: raw single source.
    return {f"{contract_name}.sol": raw}, {}


def build_settings(etherscan_settings, result):
    """
    Produce solc standard-json settings honoring optimizer/evmVersion/remappings,
    with an outputSelection that yields deployed bytecode, abi and AST.
    """
    settings = {}
    if isinstance(etherscan_settings, dict):
        for key in ("optimizer", "evmVersion", "remappings", "libraries", "viaIR", "metadata"):
            if key in etherscan_settings:
                settings[key] = etherscan_settings[key]

    # Fall back to top-level result fields when settings were absent (formats 2/3).
    if "optimizer" not in settings:
        used = str(result.get("OptimizationUsed", "0")) == "1"
        runs = result.get("Runs")
        opt = {"enabled": used}
        if runs:
            try:
                opt["runs"] = int(runs)
            except (TypeError, ValueError):
                pass
        settings["optimizer"] = opt
    if "evmVersion" not in settings:
        evm = result.get("EVMVersion")
        if evm and evm.lower() != "default":
            settings["evmVersion"] = evm

    settings["outputSelection"] = {
        "*": {
            "*": ["evm.deployedBytecode.object", "abi"],
            "": ["ast"],
        }
    }
    return settings


# --- solc ---------------------------------------------------------------------

_installed_versions = set()


def ensure_solc(version):
    if version in _installed_versions:
        return
    subprocess.run(f"solc-select install {version}", shell=True, check=True,
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    _installed_versions.add(version)


def compile_standard_json(standard_input, version):
    """Run `solc --standard-json` for the given version; return parsed output."""
    ensure_solc(version)
    subprocess.run(f"solc-select use {version}", shell=True, check=True,
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    proc = subprocess.run(
        "solc --standard-json",
        shell=True,
        input=json.dumps(standard_input),
        capture_output=True,
        text=True,
    )
    if not proc.stdout.strip():
        raise RuntimeError(f"solc produced no output: {proc.stderr[:500]}")
    return json.loads(proc.stdout)


def has_compile_errors(output):
    for err in output.get("errors", []):
        if err.get("severity") == "error":
            return err.get("formattedMessage", err.get("message", "compile error"))
    return None


def pick_contract(output, contract_name):
    """
    From solc standard-json output, return (abi, deployed_bytecode) for the
    target contract (match by name; fallback to the longest deployed bytecode).
    """
    best = None  # (length, abi, bytecode)
    target = None
    for src_path, contracts in output.get("contracts", {}).items():
        for name, cdata in contracts.items():
            bytecode = (
                cdata.get("evm", {})
                .get("deployedBytecode", {})
                .get("object", "")
            )
            abi = cdata.get("abi", [])
            if not bytecode:
                continue
            if name == contract_name:
                target = (abi, bytecode)
            if best is None or len(bytecode) > best[0]:
                best = (len(bytecode), abi, bytecode)
    if target is not None:
        return target
    if best is not None:
        return best[1], best[2]
    return None, None


# --- pipeline -----------------------------------------------------------------

def collect_addresses():
    """Unique addresses from real/*.hex filenames (strip _CCC/_DB suffixes)."""
    seen = {}
    for name in os.listdir(REAL_DIR):
        if not name.endswith(".hex") or not name.startswith("0x"):
            continue
        addr = name[:-len(".hex")]
        for suffix in ("_CCC", "_DB"):
            if addr.endswith(suffix):
                addr = addr[:-len(suffix)]
        if ADDRESS_RE.match(addr):
            seen.setdefault(addr.lower(), addr)
    return sorted(seen.values(), key=str.lower)


def write_sources(addr_dir, sources):
    src_root = os.path.join(addr_dir, "source-code")
    for rel_path, content in sources.items():
        safe_rel = rel_path.lstrip("/")
        dest = os.path.join(src_root, safe_rel)
        os.makedirs(os.path.dirname(dest), exist_ok=True)
        with open(dest, "w", encoding="utf-8") as f:
            f.write(content)


def process_address(address, api_key, force=False):
    """Returns (status, message). status in {'ok','skip','fail'}."""
    addr_dir = os.path.join(REAL_DIR, address)
    bytecode_path = os.path.join(addr_dir, "bytecode", f"{address}.bytecode")
    if os.path.exists(bytecode_path) and not force:
        return "skip", "already compiled"

    result = getsourcecode(address, api_key)
    time.sleep(REQUEST_THROTTLE_S)
    if result is None:
        return "fail", "getsourcecode returned no result"

    is_proxy = str(result.get("Proxy", "0")) == "1"
    impl_address = (result.get("Implementation") or "").strip()
    compiled_from = address

    # Proxy: follow the implementation when it is a valid, verified contract.
    if is_proxy and ADDRESS_RE.match(impl_address) and impl_address.lower() != ZERO_ADDRESS:
        impl_result = getsourcecode(impl_address, api_key)
        time.sleep(REQUEST_THROTTLE_S)
        if impl_result and (impl_result.get("SourceCode") or "").strip():
            result = impl_result
            compiled_from = impl_address
        else:
            impl_address = ""  # implementation unverified; fall back to proxy
    else:
        impl_address = ""

    if not (result.get("SourceCode") or "").strip():
        return "fail", "contract source not verified"

    contract_name = result.get("ContractName") or "Contract"
    version = parse_compiler_version(result.get("CompilerVersion"))
    if not version:
        return "fail", "missing compiler version"

    sources, etherscan_settings = parse_sources(result)
    if not sources:
        return "fail", "could not parse sources"

    write_sources(addr_dir, sources)

    standard_input = {
        "language": "Solidity",
        "sources": {path: {"content": content} for path, content in sources.items()},
        "settings": build_settings(etherscan_settings, result),
    }

    try:
        output = compile_standard_json(standard_input, version)
    except Exception as e:
        return "fail", f"compile error ({version}): {e}"

    err = has_compile_errors(output)

    abi, bytecode = pick_contract(output, contract_name)
    if not bytecode:
        return "fail", f"no deployed bytecode ({version}): {err or 'unknown'}"

    modifiers_map = collect_modifiers_from_ast(output)
    abi = attach_modifiers_to_abi(contract_name, abi, modifiers_map)

    # Persist artifacts.
    os.makedirs(os.path.join(addr_dir, "json"), exist_ok=True)
    os.makedirs(os.path.join(addr_dir, "bytecode"), exist_ok=True)
    os.makedirs(os.path.join(addr_dir, "abi"), exist_ok=True)

    with open(os.path.join(addr_dir, "json", f"{address}.json"), "w") as f:
        json.dump(output, f)
    with open(bytecode_path, "w") as f:
        f.write("0x" + bytecode)
    with open(os.path.join(addr_dir, "abi", f"{address}.abi"), "w") as f:
        json.dump(abi, f, indent=4)

    metadata = {
        "address": address,
        "is_proxy": is_proxy,
        "implementation_address": impl_address or None,
        "implementation_url": (
            f"https://etherscan.io/address/{impl_address}" if impl_address else None
        ),
        "compiler_version": version,
        "contract_name": contract_name,
        "compiled_from": compiled_from,
    }
    with open(os.path.join(addr_dir, "metadata.json"), "w") as f:
        json.dump(metadata, f, indent=4)

    return "ok", f"{contract_name} (solc {version})" + (" [proxy->impl]" if compiled_from != address else "")


def main():
    parser = argparse.ArgumentParser(description="Download + compile Smartaxe real dataset sources.")
    parser.add_argument("--address", action="append", help="Process a single address (repeatable).")
    parser.add_argument("--limit", type=int, help="Process only the first N addresses.")
    parser.add_argument("--force", action="store_true", help="Recompile even if bytecode already exists.")
    args = parser.parse_args()

    api_key = load_api_key()

    if args.address:
        addresses = args.address
    else:
        addresses = collect_addresses()
        if args.limit:
            addresses = addresses[:args.limit]

    print(f"Processing {len(addresses)} address(es).")

    failures = []
    counts = {"ok": 0, "skip": 0, "fail": 0}
    for address in tqdm(addresses, desc="Addresses"):
        try:
            status, message = process_address(address, api_key, force=args.force)
        except Exception as e:
            status, message = "fail", f"unexpected: {e}"
        counts[status] += 1
        if status == "fail":
            failures.append((address, message))
            tqdm.write(f"[FAIL] {address}: {message}")
        elif status == "ok":
            tqdm.write(f"[OK]   {address}: {message}")

    if failures:
        os.makedirs(REAL_DIR, exist_ok=True)
        with open(FAILURES_CSV, "w", newline="") as f:
            writer = csv.writer(f)
            writer.writerow(["address", "reason"])
            writer.writerows(failures)
        print(f"\n{len(failures)} failure(s) written to {FAILURES_CSV}")

    print(f"\nDone. ok={counts['ok']} skip={counts['skip']} fail={counts['fail']}")


if __name__ == "__main__":
    main()
