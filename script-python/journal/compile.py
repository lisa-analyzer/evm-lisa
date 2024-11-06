import os
import subprocess
import json
import csv
from tqdm import tqdm
import argparse

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
                f"solc --combined-json bin,bin-runtime {input_file} > {output_file} 2> /dev/null" 
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
        print(f"Installing solc {solc_version}")
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
                command = f"solc --combined-json bin,bin-runtime --pretty-json {input_file} > {output_file}"
                
                # Execute the compilation command
                try:
                    subprocess.run(command, shell=True, check=True)
                    count_success += 1
                except subprocess.CalledProcessError as e:
                    count_failure += 1
            
            # Update the progress bar
            pbar.update(1)
        
    print(f"Compiled successfully {count_success}/{count_success + count_failure} files.")

def extract_and_save_longest_bytecode(bytecode_dir, json_dir, is_ethersolve=False):
    """
    Extracts the longest bytecode based on file size from each .json file and saves it in the specified output directory.
    """
    # Clear and create bytecode directory
    clear_directory(bytecode_dir)
    os.makedirs(bytecode_dir, exist_ok=True)

    # List all .json files in the source directory
    num_files = [f for f in os.listdir(json_dir) if f.endswith('.json')]

    # Progress bar setup
    with tqdm(total=len(num_files), desc="Extracting longest bytecodes...") as pbar:
        for json_filename in os.listdir(json_dir):
            if json_filename.endswith(".json"):
                json_filepath = os.path.join(json_dir, json_filename)
                
                # Check if the file is empty
                if os.path.getsize(json_filepath) == 0:
                    print(f"Skipping empty file: {json_filename}")
                    pbar.update(1)
                    continue

                with open(json_filepath, 'r') as json_file:
                    data = json.load(json_file)
                    contracts = data.get("contracts", {})
                    
                    longest_bytecode = None
                    longest_contract_name = None
                    max_bytecode_length = 0  # Variable to store the maximum file size

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

                    # Save the longest bytecode, if it exists
                    if longest_bytecode:
                        bytecode_filename = os.path.join(
                            bytecode_dir, f"{os.path.splitext(json_filename)[0]}.bytecode"
                        )
                        with open(bytecode_filename, 'w') as bytecode_file:
                            bytecode_file.write("0x" + longest_bytecode)
                        # print(f"Extracted longest bytecode from {longest_contract_name} to {bytecode_filename}")
            # Update the progress bar
            pbar.update(1)

def extract_and_save_bytecode(bytecode_dir, json_dir, is_ethersolve=False):
    """
    Extracts all bytecode from each .json file and saves it in the specified output directory.
    """
    # Clear and create bytecode directory
    clear_directory(bytecode_dir)
    os.makedirs(bytecode_dir, exist_ok=True)

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
                        print(f"Skipping empty file: {json_filename}")
                        pbar.update(1)
                        continue
                    json_file.seek(0)  # Reset the file pointer to the beginning
                    
                    data = json.load(json_file)
                    contracts = data.get("contracts", {})
                    count = 1  # Sequential counter for each bytecode in the same JSON

                    for contract_name, contract_data in contracts.items():
                        if(is_ethersolve):
                            bytecode = contract_data.get("bin")
                        else:
                            bytecode = contract_data.get("bin-runtime")
                            
                        if bytecode:
                            # Add a sequential number to the filename
                            bytecode_filename = os.path.join(
                                bytecode_dir, f"{os.path.splitext(json_filename)[0]}_{count}.bytecode"
                            )
                            with open(bytecode_filename, 'w') as bytecode_file:                
                                bytecode_file.write("0x" + bytecode)
                            # print(f"Extracted bytecode to {bytecode_filename}")
                            count += 1  # Increment counter for next bytecode
            # Update the progress bar
            pbar.update(1)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Compile datasets.")
    parser.add_argument("--solidifi", action="store_true", help="Run analysis on SolidiFI dataset")
    parser.add_argument("--smartbugs", action="store_true", help="Run analysis on SmartBugs dataset")
    parser.add_argument("--longest-bytecode", action="store_true", help="Save only the longest bytecode")

    args = parser.parse_args()

    if not args.solidifi and not args.smartbugs:
        parser.error("At least an arg is required.")
        exit(1)

    if args.solidifi:
        compile_solidity_sources('./reentrancy-solidifi/source-code',
                                 './reentrancy-solidifi/json')
        compile_solidity_sources('./vanilla-solidifi/source-code',
                                 './vanilla-solidifi/json')
        
        if args.longest_bytecode:
            # EVMLiSA
            extract_and_save_longest_bytecode('./vanilla-solidifi/bytecode/evmlisa',
                                              './vanilla-solidifi/json')
            extract_and_save_longest_bytecode('./reentrancy-solidifi/bytecode/evmlisa',
                                              './reentrancy-solidifi/json')
            
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