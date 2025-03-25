import os
import shutil
import json
import argparse

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

if __name__ == "__main__":
    json_file_path = "benchmark_results.json"  
    analyze_vulnerabilities(json_file_path)

    # base_directory = "Real_attack_dataset_format" 
    # move_solidity_files(base_directory)
