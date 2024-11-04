import os
import subprocess
import json

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

def compile_solidity_sources(source_dir, json_dir):
    """
    Compiles all .sol files in the specified source directory using solc, 
    saving the bytecode for each file in JSON format in the specified output directory.
    """
    # Clear and create JSON output directory
    clear_directory(json_dir)
    os.makedirs(json_dir, exist_ok=True)

    # Iterate through all .sol files in the source directory
    for filename in os.listdir(source_dir):
        if filename.endswith('.sol'):
            # Full paths for input and output files
            input_file = os.path.join(source_dir, filename)
            output_file = os.path.join(json_dir, f"{os.path.splitext(filename)[0]}.json")
            
            # Command to compile and save the bytecode in JSON format
            command = f"solc --combined-json bin --pretty-json {input_file} > {output_file}"
            
            # Execute the command
            try:
                subprocess.run(command, shell=True, check=True)
                print(f"Compiled {filename} successfully.")
            except subprocess.CalledProcessError as e:
                print(f"Error compiling {filename}: {e}")

def extract_and_save_longest_bytecode(bytecode_dir, json_dir, is_ethersolve=False):
    """
    Extracts the longest bytecode from each .json file and saves it in the specified output directory.
    """
    # Clear and create bytecode directory
    clear_directory(bytecode_dir)
    os.makedirs(bytecode_dir, exist_ok=True)

    for json_filename in os.listdir(json_dir):
        if json_filename.endswith(".json"):
            json_filepath = os.path.join(json_dir, json_filename)
            with open(json_filepath, 'r') as json_file:
                data = json.load(json_file)
                contracts = data.get("contracts", {})
                
                longest_bytecode = None
                longest_contract_name = None

                for contract_name, contract_data in contracts.items():
                    bytecode = contract_data.get("bin")
                    if bytecode:
                        # Check if this bytecode is longer than the current longest
                        if longest_bytecode is None or len(bytecode) > len(longest_bytecode):
                            longest_bytecode = bytecode
                            longest_contract_name = contract_name

                # Save the longest bytecode, if it exists
                if longest_bytecode:
                    bytecode_filename = os.path.join(
                        bytecode_dir, f"{os.path.splitext(json_filename)[0]}.bytecode"
                    )
                    with open(bytecode_filename, 'w') as bytecode_file:
                        # Find the first occurrence of '60406040'
                        first_index = longest_bytecode.find('60806040')

                        # Find the second occurrence of '60406040' after the first
                        second_index = longest_bytecode.find('60806040', first_index + len('60806040'))

                        if is_ethersolve:
                                second_index = first_index
                        
                        longest_bytecode = longest_bytecode[second_index:]
                        
                        bytecode_file.write("0x" + longest_bytecode)
                    print(f"Extracted longest bytecode from {longest_contract_name} to {bytecode_filename}")

def extract_and_save_bytecode(bytecode_dir, json_dir, is_ethersolve=False):
    """
    Extracts all bytecode from each .json file and saves it in the specified output directory.
    """
    # Clear and create bytecode directory
    clear_directory(bytecode_dir)
    os.makedirs(bytecode_dir, exist_ok=True)

    for json_filename in os.listdir(json_dir):
        if json_filename.endswith(".json"):
            json_filepath = os.path.join(json_dir, json_filename)
            with open(json_filepath, 'r') as json_file:

                data = json.load(json_file)
                contracts = data.get("contracts", {})
                count = 1  # Sequential counter for each bytecode in the same JSON

                for contract_name, contract_data in contracts.items():
                    bytecode = contract_data.get("bin")
                    if bytecode:
                        # Add a sequential number to the filename
                        bytecode_filename = os.path.join(
                            bytecode_dir, f"{os.path.splitext(json_filename)[0]}_{count}.bytecode"
                        )
                        with open(bytecode_filename, 'w') as bytecode_file:
                            # Find the first occurrence of '60406040'
                            first_index = bytecode.find('60806040')

                            # Find the second occurrence of '60406040' after the first
                            second_index = bytecode.find('60806040', first_index + len('60806040'))

                            if is_ethersolve:
                                second_index = first_index
                            
                            bytecode = bytecode[second_index:]
                            
                            bytecode_file.write("0x" + bytecode)
                        print(f"Extracted bytecode to {bytecode_filename}")
                        count += 1  # Increment counter for next bytecode

if __name__ == "__main__":

    compile_solidity_sources('./reentrancy/source-code',
                             './reentrancy/json')
    compile_solidity_sources('./vanilla/source-code',
                             './vanilla/json')
    
    # EVMLiSA
    extract_and_save_longest_bytecode('./vanilla/bytecode/evmlisa',
                                      './vanilla/json')
    extract_and_save_longest_bytecode('./reentrancy/bytecode/evmlisa',
                                      './reentrancy/json')
    
    # EtherSolve
    extract_and_save_longest_bytecode('./vanilla/bytecode/ethersolve',
                                      './vanilla/json',
                                      True)
    extract_and_save_longest_bytecode('./reentrancy/bytecode/ethersolve',
                                      './reentrancy/json',
                                      True)