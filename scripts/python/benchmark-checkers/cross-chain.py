import os
import shutil
import json
import argparse
import re

def move_solidity_files(base_dir):
    for root, dirs, files in os.walk(base_dir):
        if root == base_dir:
            continue  # Skip the base directory itself
        
        # Determine the parent directory (bridge directory)
        parent_dir = os.path.dirname(root)
        source_code_dir = os.path.join(parent_dir, "source-code")
        
        # Create 'source-code' directory if it does not exist
        os.makedirs(source_code_dir, exist_ok=True)
        
        for file in files:
            if file.endswith(".sol"):
                src_path = os.path.join(root, file)
                dest_path = os.path.join(source_code_dir, file)
                
                # Handle duplicates by renaming files
                counter = 1
                while os.path.exists(dest_path):
                    file_name, file_ext = os.path.splitext(file)
                    new_file_name = f"{file_name}_{counter}{file_ext}"
                    dest_path = os.path.join(source_code_dir, new_file_name)
                    counter += 1
                
                shutil.move(src_path, dest_path)
                print(f"Moved: {src_path} -> {dest_path}")

def rename_files_in_directory(directory_path):
    """Renames files by removing '_1' suffix if no other files with the same base name exist."""
    for root, _, files in os.walk(directory_path):
        files_to_rename = [
            file for file in files if file.endswith("_1.sol")
        ]  # Collect files ending with '_1.sol'

        for file in files_to_rename:
            base_name = file[:-6]  # Remove '_1.sol'
            other_file_exists = any(
                f == f"{base_name}.sol" for f in files
            )  # Check if the base file exists

            if not other_file_exists:
                old_path = os.path.join(root, file)
                new_path = os.path.join(root, f"{base_name}.sol")
                os.rename(old_path, new_path)
                print(f"Renamed: {old_path} -> {new_path}")

def analyze_vulnerabilities_bridge(json_path):
    """Reads a JSON file and prints the vulnerability data for each bridge."""
    with open(json_path, "r", encoding="utf-8") as file:
        data = json.load(file)

    for bridge in data:
        name = bridge.get("name", "Unnamed Bridge")
        num_contracts = bridge.get("number_of_contracts", "N/A")
        print(f"Bridge: {name}")
        print(f"  Number of contracts: {num_contracts}")
        
        # Print aggregate vulnerability data
        aggregate_vulns = bridge.get("bridge_vulnerabilities", {})
        if not aggregate_vulns:
            print("  No aggregate vulnerability data available.")
        else:
            print("  Aggregate vulnerabilities:")
            for key, value in aggregate_vulns.items():
                print(f"    {key}: {value}")
        
        # Print per-contract vulnerability data
        contracts_vulns = bridge.get("contract_vulnerabilities", [])
        if not contracts_vulns:
            print("  No contract vulnerability data available.")
        else:
            total_contracts = len(contracts_vulns)
            print(f"  Vulnerability data for {total_contracts} contracts:")
            
            # Sum vulnerabilities per type across contracts
            total_vulnerabilities = {}
            for vuln_entry in contracts_vulns:
                vuln_data = vuln_entry.get("vulnerabilities", {})
                for key, value in vuln_data.items():
                    total_vulnerabilities[key] = total_vulnerabilities.get(key, 0) + value

            for key, value in total_vulnerabilities.items():
                print(f"    {key}: {value}")

        print("-" * 40)

def analyze_vulnerabilities(json_path):
    """Reads a JSON file and prints the number of vulnerabilities for each bridge."""
    with open(json_path, "r", encoding="utf-8") as file:
        data = json.load(file)

    for bridge in data:
        name = bridge["name"]
        vulnerabilities = bridge.get("vulnerabilities", [])

        num_vulnerabilities = len(vulnerabilities)

        if num_vulnerabilities == 0:
            print(f"Bridge: {name}")
            print("  No vulnerability data available.")
            print("-" * 40)
            continue

        # Inizializza un dizionario per sommare le vulnerabilità per tipo
        total_vulnerabilities = {key: 0 for key in vulnerabilities[0]["vulnerabilities"].keys()}

        for vuln_entry in vulnerabilities:
            vuln_data = vuln_entry.get("vulnerabilities", {})
            for key, value in vuln_data.items():
                total_vulnerabilities[key] += value

        print(f"Bridge: {name}")
        print(f"  Contracts analyzed: {num_vulnerabilities}")
        for key, value in total_vulnerabilities.items():
            print(f"  {key}: {value}")
        print("-" * 40)

def simplify_imports_in_solidity_files(base_dir):
    """
    Explores all .sol files in the given directory and removes folder paths from import statements.
    """
    solidity_file_pattern = re.compile(r'import\s+["\'](.+?/.+?)["\'];')
    
    for root, _, files in os.walk(base_dir):
        for file in files:
            if file.endswith(".sol"):
                file_path = os.path.join(root, file)
                
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # Replace import paths with only the file name
                modified_content = solidity_file_pattern.sub(
                    lambda match: f'import "./{os.path.basename(match.group(1))}";',
                    content
                )
                
                # Write the modified content back to the file
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(modified_content)
                
                print(f"Processed imports in: {file_path}")

def simplify_named_imports(base_dir):
    """
    Explores all .sol files in the given directory and simplifies named imports by removing folder paths.
    """
    # Regex pattern to match named imports with paths
    solidity_named_import_pattern = re.compile(r'import\s+\{(.+?)\}\s+from\s+["\'](.+?/.+?)["\'];')

    for root, _, files in os.walk(base_dir):
        for file in files:
            if file.endswith(".sol"):
                file_path = os.path.join(root, file)
                
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # Replace import paths with only the file name
                modified_content = solidity_named_import_pattern.sub(
                    lambda match: f'import {{{match.group(1).strip()}}} from "./{os.path.basename(match.group(2))}";',
                    content
                )
                
                # Write the modified content back to the file
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(modified_content)
                
                print(f"Processed named imports in: {file_path}")

def replace_specific_imports(base_dir):
    """
    Explores all .sol files in the given directory and replaces specific imports with updated paths.
    """
    # Mapping of old imports to new imports
    import_replacements = {
        './IERC20.sol': '@openzeppelin/contracts/token/ERC20/IERC20.sol',
        './ECDSA.sol': '@openzeppelin/contracts/utils/cryptography/ECDSA.sol',
        './ReentrancyGuard.sol': '@openzeppelin/contracts/utils/ReentrancyGuard.sol',
        './AccessControl.sol': '@openzeppelin/contracts/access/AccessControl.sol',
    }

    # Regex pattern to match import statements
    solidity_import_pattern = re.compile(r'import\s+["\'](.+?)["\'];')

    for root, _, files in os.walk(base_dir):
        for file in files:
            if file.endswith(".sol"):
                file_path = os.path.join(root, file)
                
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # Replace specific imports
                modified_content = solidity_import_pattern.sub(
                    lambda match: f'import "{import_replacements[match.group(1)]}";'
                    if match.group(1) in import_replacements else match.group(0),
                    content
                )
                
                # Write the modified content back to the file
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(modified_content)
                
                print(f"Processed imports in: {file_path}")

if __name__ == "__main__":
    json_file_path = "benchmark_results.json"  
    analyze_vulnerabilities(json_file_path)

    base_directory = "cross-chain/smartaxe" 
    # move_solidity_files(base_directory)
    # rename_files_in_directory(base_directory)
    # simplify_imports_in_solidity_files(base_directory)
    # simplify_named_imports(base_directory)
    # replace_specific_imports(base_directory)