import os
import subprocess
import threading
from concurrent.futures import ThreadPoolExecutor, as_completed
from tqdm import tqdm
import re
from collections import defaultdict
import matplotlib.pyplot as plt
from scipy.interpolate import make_interp_spline
import numpy as np
import json

# Directory paths
bytecode_dir = './reentrancy/bytecode'
results_dir = './reentrancy/results'
result_evmlisa_dir = results_dir + '/evmlisa'
result_ethersolve_dir = results_dir + '/ethersolve'
max_threads = int(os.cpu_count() / 3)  # Core avaiable

#################################### Utility
def delete_tmp_files(directory):
    """
    Deletes files in the specified directory that contain 'no-address' in their name.

    Args:
        directory (str): The path to the directory from which to delete files.
    """
    command = (
        f"rm -rf {directory}/no-address* "
    )
    subprocess.run(command, shell=True, check=True)

def clean_files(directory_path):
    """
    Removes lines containing "Picked up _JAVA_OPTIONS" from all files in the specified directory.
    
    Args:
        directory_path (str): The path to the directory containing files to clean.
    """
    for filename in os.listdir(directory_path):
        file_path = os.path.join(directory_path, filename)
        
        if os.path.isfile(file_path):
            with open(file_path, 'r') as file:
                lines = file.readlines()    
            
            cleaned_lines = [line for line in lines if "Picked up _JAVA_OPTIONS" not in line]
            
            if len(cleaned_lines) != len(lines):
                with open(file_path, 'w') as file:
                    file.writelines(cleaned_lines)
                # print(f"Cleaned {filename}")
            # else:
                # print(f"No changes made to {filename}")

def plot_results(data_evmlisa, data_ethersolve, data_solidifi):
    keys1 = sorted(data_ethersolve.keys())
    values1 = [data_ethersolve[key] for key in keys1]

    keys2 = sorted(data_solidifi.keys())
    values2 = [data_solidifi[key] for key in keys2]

    keys3 = sorted(data_evmlisa.keys())
    values3 = [data_evmlisa[key] for key in keys3]

    plt.figure(figsize=(12, 6))

    plt.plot(keys1, values1, marker='o', label='Ethersolve', color='purple')
    plt.plot(keys2, values2, marker='o', label='SolidiFI', color='red')
    plt.plot(keys3, values3, marker='o', label='EVMLiSA', color='green')

    plt.xlabel('Problem ID')
    plt.ylabel('Value')
    plt.title('Comparison of results (re-entrancy)')
    plt.xticks(sorted(set(keys1).union(set(keys2).union(keys3))))  # Show all problem IDs on x-axis
    plt.legend()
    plt.grid()

    plt.show()

#################################### EVMLiSA

def build_evmlisa():
    print("[EVMLISA] Building EVMLiSA...")
    command = (
        f"cd ../../ && "
        f"./gradlew build > /dev/null 2> /dev/null && "
        f"./gradlew distZip > /dev/null 2> /dev/null && "
        f"unzip -o build/distributions/evm-lisa.zip -d script-python/journal/execution > /dev/null"
    )
    subprocess.run(command, shell=True, check=True)
    print("[EVMLISA] EVMLiSA built successfully.")

def run_evmlisa(bytecode_file):
    """
    Runs the EVMLiSA analysis for a given bytecode file.
    
    Args:
        bytecode_file (str): The path to the bytecode file.
        
    Returns:
        str: The name of the results file.
    """
    bytecode_filename = os.path.basename(bytecode_file)
    result_filename = f"{os.path.splitext(bytecode_filename)[0]}-result.json"
    result_filepath = os.path.join(result_evmlisa_dir, result_filename)
    
    command = (
        f"./execution/evm-lisa/bin/evm-lisa "
        f"--filepath {bytecode_file} "
        f"--stack-size 32 "
        f"--stack-set-size 8 "
        f"--creation-code "
        f"> /dev/null 2> {result_filepath}"
    )
    
    try:
        subprocess.run(command, shell=True, check=True)
        return result_filepath
    except subprocess.CalledProcessError as e:
        print(f"[EVMLISA] Error analyzing {bytecode_file}: {e}")
        return None

def evmlisa():
    """
    Main function to run EVMLiSA analyses on multiple bytecode files.
    """
    delete_tmp_files(result_evmlisa_dir)
    os.makedirs(result_evmlisa_dir, exist_ok=True)

    # Build EVMLiSA
    build_evmlisa()
    
    # Find all bytecode files
    bytecode_files = [os.path.join(bytecode_dir, f) for f in os.listdir(bytecode_dir) if f.endswith(".bytecode")]
    num_files = len(bytecode_files)
    print(f"[EVMLISA] Found {num_files} bytecode files for analysis.")
    print(f"[EVMLISA] Starting {max_threads} parallels analysis")

    analysis_ended = 0

    # Run analyses in parallel
    with ThreadPoolExecutor(max_workers=max_threads) as executor:
        future_to_file = {executor.submit(run_evmlisa, file): file for file in bytecode_files}
        
        with tqdm(total=num_files, desc="[EVMLISA] Analyzing bytecode files") as pbar:
            for future in as_completed(future_to_file):
                result_file = future.result()
                if result_file:
                    # print(f"Analysis complete for {result_file}")
                    analysis_ended += 1
                pbar.update(1)
    
    print(f"[EVMLISA] Completed {analysis_ended}/{num_files}.")
    delete_tmp_files(results_dir)
    delete_tmp_files("./execution/results")
    clean_files(result_evmlisa_dir)
    print(f"[EVMLISA] File cleaned.")

def check_sound_analysis_evmlisa(directory_path):
    sound = True
    
    for filename in os.listdir(directory_path):
        if filename.endswith(".json"):
            file_path = os.path.join(directory_path, filename)
            try:
                with open(file_path, 'r') as file:
                    data = json.load(file)
                    
                    if "solved-jumps-percent" in data:
                        if data["solved-jumps-percent"] != 1:
                            print(f"[EVMLiSA] {filename} - solved-jumps-percent: {data['solved-jumps-percent']}")
                            sound = False
                    else:
                        print(f"[EVMLiSA] Warning: 'solved-jumps-percent' not found in {filename}")
            except Exception as e:
                print(f"[EVMLiSA] ERROR: {filename}: {e}")
    
    if sound:
        print("[EVMLiSA] All analysis are SOUND")

def results_evmlisa(directory_path):
    re_entrancy_warning_counts = {}
    
    for filename in os.listdir(directory_path):
        if filename.endswith(".json"):
            file_path = os.path.join(directory_path, filename)
            try:
                with open(file_path, 'r') as file:
                    data = json.load(file)
                    
                    if "re-entrancy-warning" in data:
                        re_entrancy_warning_counts[filename] = data['re-entrancy-warning']
                    else:
                        print(f"[EVMLiSA] Warning: 're-entrancy-warning' not found in {filename}")
            except Exception as e:
                print(f"[EVMLiSA] ERROR: {filename}: {e}")            

    results = defaultdict(int)
    for file, result in re_entrancy_warning_counts.items():
        match = re.match(r'buggy_(\d+)-\w+\.json', file)
        if match:
            id = int(match.group(1))
            results[id] += result
        
        match = re.match(r'buggy_(\d+)_(\d+)-\w+\.json', file)
        if match:
            id = int(match.group(1))
            results[id] += result
    
    sorted_data = dict(sorted(results.items()))
    print(sorted_data)
    return sorted_data


#################################### EtherSolve

def run_ethersolve(bytecode_file):
    """
    Runs the EtherSolve analysis for a given bytecode file.
    
    Args:
        bytecode_file (str): The path to the bytecode file.
        
    Returns:
        str: The name of the results file.
    """
    bytecode_filename = os.path.basename(bytecode_file)
    filename = os.path.splitext(bytecode_filename)[0]
    result_filename = filename + "-result.json"
    result_filepath = os.path.join(result_ethersolve_dir, result_filename)
    
    command = (
        f"sleep 0.9 && "
        f"java -jar EtherSolve/EtherSolve.jar "
        f"--re-entrancy "
        f"-o {result_filepath} "        
        f"--creation --json "
        f"{bytecode_file} 2> /dev/null && "
        f"mv *re-entrancy.csv {result_ethersolve_dir}/{filename}-reentrancy.csv"
    )
    
    try:
        subprocess.run(command, shell=True, check=True)
        return result_filepath
    except subprocess.CalledProcessError as e:
        # print(f"[ETHERSOLVE] Error analyzing {bytecode_file}: {e}")
        return None

def ethersolve():
    """
    Main function to run EtherSolve analyses on multiple bytecode files.
    """
    delete_tmp_files(result_ethersolve_dir)
    os.makedirs(result_ethersolve_dir, exist_ok=True)
    
    # Find all bytecode files
    bytecode_files = [os.path.join(bytecode_dir, f) for f in os.listdir(bytecode_dir) if f.endswith(".bytecode")]
    num_files = len(bytecode_files)
    print(f"[ETHERSOLVE] Found {num_files} bytecode files for analysis.")
    print(f"[ETHERSOLVE] Starting analysis")

    analysis_ended = 0

    # Run analyses in parallel
    with ThreadPoolExecutor(max_workers=1) as executor:
        future_to_file = {executor.submit(run_ethersolve, file): file for file in bytecode_files}
        
        with tqdm(total=num_files, desc="[ETHERSOLVE] Analyzing bytecode files") as pbar:
            for future in as_completed(future_to_file):
                result_file = future.result()
                if result_file:
                    # print(f"Analysis complete for {result_file}")
                    analysis_ended += 1
                pbar.update(1)
    print(f"[ETHERSOLVE] Completed {analysis_ended}/{num_files}.")
    delete_tmp_files(bytecode_dir)

def results_ethersolve(directory_path):
    """
    Counts occurrences of the word "SSTORE" in files with "reentrancy" in their names 
    within the specified directory.

    Args:
        directory_path (str): The path to the directory containing files to search.
    """
    sstore_counts = {}

    for filename in os.listdir(directory_path):
        if "reentrancy" in filename:
            file_path = os.path.join(directory_path, filename)
            if os.path.isfile(file_path):
                with open(file_path, 'r') as file:
                    content = file.read()
                
                sstore_count = content.count("SSTORE")
                
                # print(f"{filename}: {sstore_count}")
                sstore_counts[filename] = sstore_count

    results = defaultdict(int)
    for file, result in sstore_counts.items():
        match = re.match(r'buggy_(\d+)-\w+\.csv', file)
        if match:
            id = int(match.group(1))
            results[id] += result
    
    sorted_data = dict(sorted(results.items()))
    # print(sorted_data)
    return sorted_data

#################################### SolidiFI

def results_solidifi(folder_path):
    # Initialize a dictionary to store the line count for each problem ID
    line_counts = defaultdict(int)

    # Iterate over all files in the specified folder
    for file_name in os.listdir(folder_path):
        # Check if the file name matches the pattern "BugLog_<problem number>.csv"
        match = re.match(r'BugLog_(\d+)\.csv', file_name)
        if match:
            # Extract the problem number from the file name
            problem_id = int(match.group(1))
            file_path = os.path.join(folder_path, file_name)
            
            # Count the number of lines in the file
            with open(file_path, 'r') as file:
                num_lines = sum(1 for _ in file)
                
            # Store the line count in the dictionary
            line_counts[problem_id] = num_lines - 1

    sorted_data = dict(sorted(line_counts.items()))
    # print(sorted_data)
    return sorted_data

#################################### Main

if __name__ == "__main__":

    evmlisa_thread = threading.Thread(target=evmlisa)
    ethersolve_thread = threading.Thread(target=ethersolve)
    
    evmlisa_thread.start()
    ethersolve_thread.start()

    evmlisa_thread.join()
    ethersolve_thread.join()

    check_sound_analysis_evmlisa(result_evmlisa_dir)

    plot_results(
        results_evmlisa(result_evmlisa_dir),
        results_ethersolve(result_ethersolve_dir),
        results_solidifi("./SolidiFI-benchmark/buggy_contracts/Re-entrancy")
    )
    