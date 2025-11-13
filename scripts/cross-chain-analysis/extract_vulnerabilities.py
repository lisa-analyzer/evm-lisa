#!/usr/bin/env python3
"""
Script to extract vulnerabilities from JSON and export to CSV
"""

import json
import csv
import sys
from pathlib import Path


def normalize_vulnerability_name(vuln_string):
    """
    Converts vulnerability name to lowercase with underscores.
    Extracts only the vulnerability type (e.g., "Access Control Incompleteness" -> "access_control_incompleteness")
    """
    # Extract vulnerability type (part before "vulnerability in")
    if "vulnerability in" in vuln_string:
        vuln_type = vuln_string.split(" vulnerability in")[0].strip()
        # Remove prefixes like "[DEFINITE]"
        if vuln_type.startswith("[DEFINITE] "):
            vuln_type = vuln_type.replace("[DEFINITE] ", "").strip()
        # Convert to lowercase and replace spaces with underscores
        vuln_type = vuln_type.lower().replace(" ", "_")
        return vuln_type
    return ""


def extract_function_name(vuln_string):
    """
    Extracts the function name from the vulnerability string.
    E.g., "Missing State Update vulnerability in 4_1 at depositIncentives(address,uint256) (pc: 568, line: 300)"
    -> "depositIncentives(address,uint256)"
    """
    if " at " in vuln_string:
        # Get the part after " at "
        after_at = vuln_string.split(" at ", 1)[1]
        # Extract the function name (part before the first space which contains "pc:")
        if " (pc:" in after_at:
            function_name = after_at.split(" (pc:")[0].strip()
            return function_name
    return ""


def extract_data_from_json(json_file):
    """
    Extracts data from JSON and formats it for CSV, removing duplicates
    """
    with open(json_file, 'r') as f:
        data = json.load(f)

    rows = []
    seen = set()  # Track seen rows to remove duplicates

    for bridge_entry in data:
        bridge = bridge_entry.get("bridge", "")
        contracts = bridge_entry.get("contracts", [])

        for contract in contracts:
            vulnerabilities = contract.get("vulnerabilities", [])

            # Skip contracts without vulnerabilities
            if not vulnerabilities:
                continue

            source_code_name = contract.get("source-code-name", "")
            # Add .sol extension if not present
            if source_code_name and not source_code_name.endswith(".sol"):
                source_code_name += ".sol"

            # For each vulnerability, create a row
            for vuln in vulnerabilities:
                normalized_vuln = normalize_vulnerability_name(vuln)
                function_name = extract_function_name(vuln)

                row = {
                    'tool': 'xEVMLiSA',
                    'bridge': bridge,
                    'vulnerability_type': normalized_vuln,
                    'file': source_code_name,
                    'contract': '',
                    'function': function_name,
                    'type': '',
                    'notes': ''
                }

                # Create a tuple key for duplicate detection
                row_key = (bridge, normalized_vuln, source_code_name, function_name)

                if row_key not in seen:
                    seen.add(row_key)
                    rows.append(row)

    return rows


def save_to_csv(rows, output_file):
    """
    Saves data in CSV format
    """
    if not rows:
        print("No data to export (no contracts with vulnerabilities found)")
        return

    fieldnames = ['tool', 'bridge', 'vulnerability_type', 'file', 'contract', 'function', 'type', 'notes']

    with open(output_file, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)

    print(f"✓ File saved: {output_file}")
    print(f"  Rows exported: {len(rows)}")


def main():
    script_dir = Path(__file__).parent

    # Accept input filename from command line
    if len(sys.argv) < 2:
        print("Usage: python3 extract_vulnerabilities.py <input_json_file> [output_csv_file]")
        print("Example: python3 extract_vulnerabilities.py benchmark_results_function.json")
        sys.exit(1)

    input_filename = sys.argv[1]
    json_file = script_dir / input_filename

    # Output file defaults to input filename without extension + ".csv"
    if len(sys.argv) >= 3:
        output_filename = sys.argv[2]
        output_file = script_dir / output_filename
    else:
        output_filename = input_filename.rsplit('.', 1)[0] + ".csv"
        output_file = script_dir / output_filename

    if not json_file.exists():
        print(f"Error: JSON file not found: {json_file}")
        sys.exit(1)

    print(f"Reading data from: {json_file}")
    rows = extract_data_from_json(json_file)

    print(f"Data extracted: {len(rows)} rows")
    save_to_csv(rows, output_file)


if __name__ == "__main__":
    main()
