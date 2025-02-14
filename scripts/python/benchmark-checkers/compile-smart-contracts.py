import os
import subprocess
import json
import csv
from tqdm import tqdm
import argparse

import re

def clear_directory(directory):
    """
    Clears all files in the specified directory.
    """
    if os.path.exists(directory):
        for file in os.listdir(directory):
            file_path = os.path.join(directory, file)
            try:
                os.remove(file_path)
            except Exception as e:
                print(f"Error deleting {file_path}: {e}")

def load_version_mapping(version_file):
    """
    Loads the compiler version mapping from a CSV file.
    Returns a dictionary where the key is the file path and the value is the compiled version.
    """
    version_mapping = {}
    with open(version_file, mode='r') as file:
        csv_reader = csv.DictReader(file)
        for row in csv_reader:
            version_mapping[row['file']] = row['compiled version']
    return version_mapping

def generate_file_index(folder_path, output_json="file_index.json"):
    file_index = {}
    
    files = sorted(f for f in os.listdir(folder_path) if f.endswith(".sol") and os.path.isfile(os.path.join(folder_path, f)))
    
    for i, file_name in enumerate(files, start=1):
        file_name_no_ext = os.path.splitext(file_name)[0] 
        file_index[file_name_no_ext] = i

    with open(output_json, 'w', encoding='utf-8') as json_file:
        json.dump(file_index, json_file, indent=4)
    
    print(f"File index saved in {output_json}")

def extract_solidity_versions(src_folder, output_csv="solidity_versions.csv"):
    data = []
    pragma_regex = re.compile(r'pragma\s+solidity\s+([^;]+);')

    for root, _, files in os.walk(src_folder):
        for file_name in files:
            if file_name.endswith(".sol"):
                file_path = os.path.join(root, file_name)
                with open(file_path, 'r', encoding='utf-8') as file:
                    content = file.read()

                    pragma_match = pragma_regex.search(content)
                    if pragma_match:
                        original_version = pragma_match.group(1).strip()
                        
                        cleaned_version = re.sub(r"[^\d\.\s]", "", original_version).strip()
                        versions = cleaned_version.split()

                        compiled_version = versions[0]

                        data.append({
                            "file": file_name,
                            "original pragma version": original_version,
                            "compiled version": compiled_version,
                            "notes": ""
                        })

    with open(output_csv, 'w', newline='', encoding='utf-8') as csv_file:
        fieldnames = ["file", "original pragma version", "compiled version", "notes"]
        writer = csv.DictWriter(csv_file, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(data)

    print(f"Versions saved in {output_csv}")

def compile_solidity_sources_with_different_version(source_dir, json_dir, version_file):
    """
    Compiles all .sol files in the specified source directory using different versions of solc, 
    saving the bytecode for each file in JSON format in the specified output directory.
    """
    version_mapping = load_version_mapping(version_file)
    installed_versions = set()  # Set to keep track of installed versions
    count_success = 0
    count_failure = 0

    # Clear and create JSON output directory
    clear_directory(json_dir)
    os.makedirs(json_dir, exist_ok=True)

    # List all .sol files in the source directory
    sol_files = [f for f in os.listdir(source_dir) if f.endswith('.sol')]

    # Progress bar setup
    with tqdm(total=len(sol_files), desc="Compiling files...") as pbar:
        for filename in sol_files:
            # Full paths for input and output files
            input_file = os.path.join(source_dir, filename)
            output_file = os.path.join(json_dir, f"{os.path.splitext(filename)[0]}.json")

            compiled_version = version_mapping.get(filename, None)
            
            if compiled_version is None:
                print(f"Version not specified for {filename} in {version_file}. Skipping file.")
                pbar.update(1)
                continue

            # Install the version if not already installed
            if compiled_version not in installed_versions:
                try:
                    install_command = f"solc-select install {compiled_version} > /dev/null"
                    subprocess.run(install_command, shell=True, check=True)
                    installed_versions.add(compiled_version)  # Mark version as installed
                except subprocess.CalledProcessError as e:
                    print(f"Error installing solc version {compiled_version}: {e}")
                    pbar.update(1)
                    continue

            # Command to compile and save the bytecode in JSON format
            command = (
                f"solc-select use {compiled_version} > /dev/null && "
                f"solc --combined-json bin,bin-runtime,abi {input_file} > {output_file} 2> /dev/null" 
            )
            
            # Execute the compilation command
            try:
                subprocess.run(command, shell=True, check=True)
                count_success += 1
            except subprocess.CalledProcessError as e:
                count_failure += 1
            
            # Update the progress bar
            pbar.update(1)
        
    print(f"Compiled successfully {count_success}/{count_success + count_failure} files.")

def compile_solidity_sources(source_dir, json_dir):
    """
    Compiles all .sol files in the specified source directory using solc, 
    saving the bytecode for each file in JSON format in the specified output directory.
    """
    # Clear and create JSON output directory
    clear_directory(json_dir)
    os.makedirs(json_dir, exist_ok=True)

    count_success = 0
    count_failure = 0
    solc_version = '0.5.12'

    try:
        # print(f"Installing solc {solc_version}")
        install_command = (
            f"solc-select install {solc_version} > /dev/null &&"
            f"solc-select use {solc_version} > /dev/null"
        )
        subprocess.run(install_command, shell=True, check=True)
    except subprocess.CalledProcessError as e:
        print(f"Error installing solc version {solc_version}: {e}")

    # List all .sol files in the source directory
    sol_files = [f for f in os.listdir(source_dir) if f.endswith('.sol')]

    # Progress bar setup
    with tqdm(total=len(sol_files), desc="Compiling files...") as pbar:
        for filename in sol_files:
            if filename.endswith('.sol'):
                # Full paths for input and output files
                input_file = os.path.join(source_dir, filename)
                output_file = os.path.join(json_dir, f"{os.path.splitext(filename)[0]}.json")
                
                # Command to compile and save the bytecode in JSON format
                command = f"solc --combined-json bin,bin-runtime,abi --pretty-json {input_file} > {output_file} 2> /dev/null "
                
                # Execute the compilation command
                try:
                    subprocess.run(command, shell=True, check=True)
                    count_success += 1
                except subprocess.CalledProcessError as e:
                    count_failure += 1
            
            # Update the progress bar
            pbar.update(1)
        
    print(f"Compiled successfully {count_success}/{count_success + count_failure} files.")

def extract_and_save_longest_bytecode(bytecode_dir, json_dir, is_ethersolve=False, file_index=None, abi_dir=None):
    """
    Extracts the longest bytecode based on file size from each .json file and saves it in the specified output directory.
    """
    # Clear and create bytecode directory
    clear_directory(bytecode_dir)
    os.makedirs(bytecode_dir, exist_ok=True)
    if abi_dir is not None:
        clear_directory(abi_dir)
        os.makedirs(abi_dir, exist_ok=True)

    # List all .json files in the source directory
    num_files = [f for f in os.listdir(json_dir) if f.endswith('.json')]

    # Progress bar setup
    with tqdm(total=len(num_files), desc="Extracting longest bytecodes...") as pbar:
        for json_filename in os.listdir(json_dir):
            if json_filename.endswith(".json"):
                json_filepath = os.path.join(json_dir, json_filename)
                
                # Check if the file is empty
                if os.path.getsize(json_filepath) == 0:
                    # print(f"Skipping empty file: {json_filename}")
                    pbar.update(1)
                    continue

                with open(json_filepath, 'r') as json_file:
                    data = json.load(json_file)
                    contracts = data.get("contracts", {})
                    
                    longest_bytecode = None
                    longest_contract_name = None
                    max_bytecode_length = 0  # Variable to store the maximum file size
                    abi = None

                    # Find the contract with the longest bytecode
                    for contract_name, contract_data in contracts.items():
                        if(is_ethersolve):
                            bytecode = contract_data.get("bin")
                        else:
                            bytecode = contract_data.get("bin-runtime")
                        if bytecode:
                            bytecode_length = len(bytecode)
                            # Check if this bytecode is longer than the current longest
                            if bytecode_length > max_bytecode_length:
                                max_bytecode_length = bytecode_length
                                longest_bytecode = bytecode
                                longest_contract_name = contract_name
                                abi = contract_data.get("abi")

                    # Save the longest bytecode, if it exists
                    if longest_bytecode:
                        base_filename = os.path.splitext(json_filename)[0]
                        
                        if file_index is not None:
                            file_id = file_index.get(base_filename)  # Match string name to integer
                            base_filename = str(file_id) if file_id is not None else base_filename
                        
                        bytecode_filename = os.path.join(bytecode_dir, f"{base_filename}.bytecode")
                        
                        with open(bytecode_filename, 'w') as bytecode_file:
                            bytecode_file.write("0x" + longest_bytecode)
                        
                        # Save ABI if available
                        if abi and abi_dir is not None:
                            abi_filename = os.path.join(abi_dir, f"{base_filename}.abi.json")
                            
                            if isinstance(abi, str):  
                                abi = json.loads(abi)
                            
                            with open(abi_filename, 'w') as abi_file:
                                json.dump(abi, abi_file, indent=4)
            # Update the progress bar
            pbar.update(1)

def extract_and_save_bytecode(bytecode_dir, json_dir, is_ethersolve=False, file_index=None, abi_dir=None):
    """
    Extracts all bytecode from each .json file and saves it in the specified output directory.
    """
    # Clear and create bytecode directory
    clear_directory(bytecode_dir)
    os.makedirs(bytecode_dir, exist_ok=True)
    if abi_dir is not None:
        clear_directory(abi_dir)
        os.makedirs(abi_dir, exist_ok=True)

    # List all .sol files in the source directory
    num_files = [f for f in os.listdir(json_dir) if f.endswith('.json')]

    # Progress bar setup
    with tqdm(total=len(num_files), desc="Extracting files...") as pbar:
        for json_filename in os.listdir(json_dir):
            if json_filename.endswith(".json"):
                json_filepath = os.path.join(json_dir, json_filename)
                with open(json_filepath, 'r') as json_file:
                    # Check if the file is empty by reading the first character
                    if json_file.read(1) == "":
                        # print(f"Skipping empty file: {json_filename}")
                        pbar.update(1)
                        continue
                    json_file.seek(0)  # Reset the file pointer to the beginning
                    
                    data = json.load(json_file)
                    contracts = data.get("contracts", {})
                    count = 1  # Sequential counter for each bytecode in the same JSON
                    abi = None

                    for contract_name, contract_data in contracts.items():
                        if(is_ethersolve):
                            bytecode = contract_data.get("bin")
                        else:
                            bytecode = contract_data.get("bin-runtime")
                        abi = contract_data.get("abi")
                            
                        if bytecode:
                            bytecode_filename = os.path.join(
                                bytecode_dir, f"{os.path.splitext(json_filename)[0]}_{count}.bytecode"
                            )

                            if file_index is not None:
                                file_id = file_index.get(os.path.splitext(json_filename)[0]) # Match string name to integer
                                # Add a sequential number to the filename
                                bytecode_filename = os.path.join(
                                    bytecode_dir, f"{file_id}_{count}.bytecode"
                                )

                            with open(bytecode_filename, 'w') as bytecode_file:                
                                bytecode_file.write("0x" + bytecode)

                            # Save ABI if available
                            if abi and abi_dir is not None:
                                abi_filename = os.path.join(abi_dir, f"{file_id}_{count}.abi.json")
                                
                                if isinstance(abi, str):  
                                    abi = json.loads(abi)
                                
                                with open(abi_filename, 'w') as abi_file:
                                    json.dump(abi, abi_file, indent=4)

                            # print(f"Extracted bytecode to {bytecode_filename}")
                            count += 1  # Increment counter for next bytecode
            # Update the progress bar
            pbar.update(1)

def compile_bridge(name):
    extract_solidity_versions(src_folder=f'./{name}/source-code',
                              output_csv=f'./{name}/source-code/version.csv')
    
    compile_solidity_sources_with_different_version(source_dir=f'./{name}/source-code',
                                                    json_dir=f'./{name}/json',
                                                    version_file=f'./{name}/source-code/version.csv')
    
    generate_file_index(folder_path=f'./{name}/source-code',
                        output_json=f'./{name}/match-file-index.json')
    
    with open(f'./{name}/match-file-index.json', 'r') as index_file:
        match_file_index = json.load(index_file)

    extract_and_save_bytecode(bytecode_dir=f'./{name}/bytecode',
                                json_dir=f'./{name}/json',
                                abi_dir=f'./{name}/abi',
                                file_index=match_file_index)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Compile datasets.")
    parser.add_argument("--solidifi", action="store_true", help="Compile SolidiFI dataset")
    parser.add_argument("--smartbugs", action="store_true", help="Compile SmartBugs dataset")
    parser.add_argument("--slise", action="store_true", help="Compile SliSE dataset")
    parser.add_argument("--longest-bytecode", action="store_true", help="Save only the longest bytecode")
    parser.add_argument("--manual", action="store_true", help="Manual mode")
    parser.add_argument("--cross-chain-xguard", action="store_true", help="Compile XGuard dataset")

    args = parser.parse_args()

    if args.cross_chain_xguard:
        compile_bridge('cross-chain/XGuard/QBridge') # QBridge
        compile_bridge('cross-chain/XGuard/MeterBridge') # MeterBridge

    if args.manual:
        # Test ThorChain Bridge
        extract_solidity_versions(src_folder='./cross-chain/THORChain-bridge/source-code',
                                  output_csv='./cross-chain/THORChain-bridge/source-code/version.csv')
        compile_solidity_sources_with_different_version(source_dir='./cross-chain/THORChain-bridge/source-code',
                                                        json_dir='./cross-chain/THORChain-bridge/json',
                                                        version_file='./cross-chain/THORChain-bridge/source-code/version.csv')
        extract_and_save_longest_bytecode(bytecode_dir='./cross-chain/THORChain-bridge/bytecode/',
                                          json_dir='./cross-chain/THORChain-bridge/json',
                                          abi_dir='./cross-chain/THORChain-bridge/abi/')

    if args.solidifi:
        compile_solidity_sources('./reentrancy-solidifi/source-code',
                                 './reentrancy-solidifi/json')
        compile_solidity_sources('./vanilla-solidifi/source-code',
                                 './vanilla-solidifi/json')
        compile_solidity_sources('./tx-origin-solidifi/source-code',
                                 './tx-origin-solidifi/json')
        compile_solidity_sources('./timestamp-dependency-solidifi/source-code',
                                 './timestamp-dependency-solidifi/json')
        
        if args.longest_bytecode:
            # EVMLiSA
            extract_and_save_longest_bytecode('./vanilla-solidifi/bytecode/evmlisa',
                                              './vanilla-solidifi/json',
                                              abi_dir='./vanilla-solidifi/abi/evmlisa')
            extract_and_save_longest_bytecode('./reentrancy-solidifi/bytecode/evmlisa',
                                              './reentrancy-solidifi/json',
                                              abi_dir='./reentrancy-solidifi/abi/evmlisa')
                # TX-ORIGIN
            extract_and_save_longest_bytecode('./tx-origin-solidifi/bytecode/evmlisa',
                                              './tx-origin-solidifi/json')

                # Timestamp-dependency
            extract_and_save_longest_bytecode('./timestamp-dependency-solidifi/bytecode/evmlisa',
                                              './timestamp-dependency-solidifi/json')

            # EtherSolve
            extract_and_save_longest_bytecode('./vanilla-solidifi/bytecode/ethersolve',
                                              './vanilla-solidifi/json',
                                              True)
            extract_and_save_longest_bytecode('./reentrancy-solidifi/bytecode/ethersolve',
                                              './reentrancy-solidifi/json',
                                              True)
        else:
            # EVMLiSA
            extract_and_save_bytecode('./vanilla-solidifi/bytecode/evmlisa',
                                      './vanilla-solidifi/json')
            extract_and_save_bytecode('./reentrancy-solidifi/bytecode/evmlisa',
                                      './reentrancy-solidifi/json')
                # TX-ORIGIN
            extract_and_save_bytecode('./tx-origin-solidifi/bytecode/evmlisa',
                                      './tx-origin-solidifi/json')

                # Timestamp-dependency
            extract_and_save_bytecode('./timestamp-dependency-solidifi/bytecode/evmlisa',
                                      './timestamp-dependency-solidifi/json')
            
            # EtherSolve
            extract_and_save_bytecode('./vanilla-solidifi/bytecode/ethersolve',
                                      './vanilla-solidifi/json',
                                      True)
            extract_and_save_bytecode('./reentrancy-solidifi/bytecode/ethersolve',
                                      './reentrancy-solidifi/json',
                                      True)
    
    if args.smartbugs:
        compile_solidity_sources_with_different_version('./reentrancy-smartbugs/source-code',
                                                        './reentrancy-smartbugs/json',
                                                        './reentrancy-smartbugs/source-code/version.csv')

        if args.longest_bytecode:
            extract_and_save_longest_bytecode('./reentrancy-smartbugs/bytecode/evmlisa',
                                              './reentrancy-smartbugs/json')
            extract_and_save_longest_bytecode('./reentrancy-smartbugs/bytecode/ethersolve',
                                              './reentrancy-smartbugs/json',
                                              True)
        else:
            extract_and_save_bytecode('./reentrancy-smartbugs/bytecode/evmlisa',
                                      './reentrancy-smartbugs/json')
            extract_and_save_bytecode('./reentrancy-smartbugs/bytecode/ethersolve',
                                      './reentrancy-smartbugs/json',
                                      True)
    
    if args.slise:
        extract_solidity_versions('./reentrancy-slise-db1/source-code',
                                  './reentrancy-slise-db1/source-code/version.csv')
        generate_file_index('./reentrancy-slise-db1/source-code',
                            './reentrancy-slise-db1/match-file-index.json')
        compile_solidity_sources_with_different_version('./reentrancy-slise-db1/source-code',
                                                        './reentrancy-slise-db1/json',
                                                        './reentrancy-slise-db1/source-code/version.csv')
        
        with open('./reentrancy-slise-db1/match-file-index.json', 'r') as index_file:
            match_file_index = json.load(index_file)

        if args.longest_bytecode:
            extract_and_save_longest_bytecode('./reentrancy-slise-db1/bytecode/evmlisa',
                                              './reentrancy-slise-db1/json',
                                              False,
                                              match_file_index)
            extract_and_save_longest_bytecode('./reentrancy-slise-db1/bytecode/ethersolve',
                                              './reentrancy-slise-db1/json',
                                              True,
                                              match_file_index)
        else:
            
            extract_and_save_bytecode('./reentrancy-slise-db1/bytecode/evmlisa',
                                      './reentrancy-slise-db1/json', 
                                      False, 
                                      match_file_index)
            extract_and_save_bytecode('./reentrancy-slise-db1/bytecode/ethersolve',
                                      './reentrancy-slise-db1/json',
                                      True,
                                      match_file_index)