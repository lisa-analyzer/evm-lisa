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
from datetime import datetime
import argparse

max_threads = int(os.cpu_count() / 2)  # Core avaiable

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

def delete_files(directory):
    """
    Deletes all files in the specified directory.

    Args:
        directory (str): The path to the directory from which to delete files.
    """
    command = (
        f"rm -rf {directory}/* "
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

def plot_results(data_evmlisa, data_ethersolve, data_solidifi, name="no-name"):
    os.makedirs('./images', exist_ok=True)

    keys1 = sorted(data_ethersolve.keys())
    values1 = [data_ethersolve[key] for key in keys1]

    keys2 = sorted(data_solidifi.keys())
    values2 = [data_solidifi[key] for key in keys2]

    keys3 = sorted(data_evmlisa.keys())
    values3 = [data_evmlisa[key] for key in keys3]

    plt.figure(figsize=(12, 6))

    plt.plot(keys1, values1, marker='o', label='Ethersolve', color='purple')
    plt.plot(keys2, values2, marker='o', label='Truth', color='red')
    plt.plot(keys3, values3, marker='o', label='EVMLiSA', color='green', linestyle='--', zorder=3)

    plt.xlabel('Problem ID')
    plt.ylabel('Value')
    plt.title(f'[{name}] Comparison of results (re-entrancy)')
    plt.xticks(sorted(set(keys1).union(set(keys2).union(keys3))))  # Show all problem IDs on x-axis
    plt.legend()
    plt.grid()

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"results_{name}_{timestamp}.png"
    plt.savefig('images/' + filename)

    plt.show()

def plot_results(data_evmlisa, data_solidifi, name="no-name"):
    os.makedirs('./images', exist_ok=True)


    keys2 = sorted(data_solidifi.keys())
    values2 = [data_solidifi[key] for key in keys2]

    keys3 = sorted(data_evmlisa.keys())
    values3 = [data_evmlisa[key] for key in keys3]

    plt.figure(figsize=(12, 6))

    plt.plot(keys2, values2, marker='o', label='Truth', color='red')
    plt.plot(keys3, values3, marker='o', label='EVMLiSA', color='green', linestyle='--', zorder=3)

    plt.xlabel('Problem ID')
    plt.ylabel('Value')
    plt.title(f'[{name}] Comparison of results (tx-origin)')
    plt.xticks(sorted(set(keys2).union(keys3)))  # Show all problem IDs on x-axis
    plt.legend()
    plt.grid()

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"results_{name}_{timestamp}.png"
    plt.savefig('images/' + filename)

    plt.show()

def plot_results(data_evmlisa, data_solidifi, name="no-name"):
    os.makedirs('./images', exist_ok=True)


    keys2 = sorted(data_solidifi.keys())
    values2 = [data_solidifi[key] for key in keys2]

    keys3 = sorted(data_evmlisa.keys())
    values3 = [data_evmlisa[key] for key in keys3]

    plt.figure(figsize=(12, 6))

    plt.plot(keys2, values2, marker='o', label='Truth', color='red')
    plt.plot(keys3, values3, marker='o', label='EVMLiSA', color='green', linestyle='--', zorder=3)

    plt.xlabel('Problem ID')
    plt.ylabel('Value')
    plt.title(f'[{name}] Comparison of results (timestamp-dependency)')
    plt.xticks(sorted(set(keys2).union(keys3)))  # Show all problem IDs on x-axis
    plt.legend()
    plt.grid()

    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"results_{name}_{timestamp}.png"
    plt.savefig('images/' + filename)

    plt.show()

def subtract_dicts(dict1, dict2):
    result = {}
    
    for key in dict1:
        if key in dict2:
            result[key] = dict1[key] - dict2[key]
        else:
            result[key] = dict1[key]
    
    return result

def calculate_average(data):
    if not data:
        return 0 

    total = sum(data.values())
    count = len(data)

    average_precision = total / count
    return average_precision

def map_file_names_to_ids(sorted_data, index_path):
    """
    Map the file names in sorted_data to their corresponding IDs from the index JSON.
    """
    
    with open(index_path, 'r') as index_file:
        file_index = json.load(index_file)

    mapped_data = {}

    for file_name, count in sorted_data.items():
        file_id = file_index.get(file_name)
        if file_id is not None:
            mapped_data[file_id] = count

    return mapped_data

#################################### EVMLiSA

def build_evmlisa():
    print("[EVMLISA] Building EVMLiSA...")
    command = (
        f"cd ../../../ && "
        f"./gradlew assemble > /dev/null 2> /dev/null && "
        f"cp -r build/libs/evm-lisa-all.jar scripts/python/benchmark-checkers/execution/evm-lisa.jar > /dev/null"
    )
    subprocess.run(command, shell=True, check=True)
    print("[EVMLISA] EVMLiSA built successfully.")

def run_evmlisa(bytecode_file, result_evmlisa_dir, type="reentrancy"):
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
        f"java -jar execution/evm-lisa.jar "
        f"--filepath-bytecode {bytecode_file} "
        f"--stack-size 40 "
        f"--stack-set-size 15 "
        f"--creation-code "
        f"--checker-{type} "
        f"--link-unsound-jumps-to-all-jumpdest "
        # f"--dump-report "
        # f"--output {os.path.splitext(bytecode_filename)[0]}"
        f"> /dev/null 2> {result_filepath}"
    )
    
    try:
        subprocess.run(command, shell=True, check=True)
        return result_filepath
    except subprocess.CalledProcessError as e:
        print(f"[EVMLISA] Error analyzing {bytecode_file}: {e}")
        return None

def evmlisa(bytecode_dir, results_dir, result_evmlisa_dir, type="reentrancy"):
    """
    Main function to run EVMLiSA analyses on multiple bytecode files.
    """
    delete_files(result_evmlisa_dir)
    os.makedirs(result_evmlisa_dir, exist_ok=True)
    
    # Find all bytecode files
    bytecode_files = [os.path.join(bytecode_dir, f) for f in os.listdir(bytecode_dir) if f.endswith(".bytecode")]
    num_files = len(bytecode_files)
    print(f"[EVMLISA] Found {num_files} bytecode files for analysis.")
    print(f"[EVMLISA] Starting {max_threads} parallels analysis...")

    analysis_ended = 0

    # Run analyses in parallel
    with ThreadPoolExecutor(max_workers=max_threads) as executor:
        future_to_file = {executor.submit(run_evmlisa, file, result_evmlisa_dir, type): file for file in bytecode_files}
        
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
                        if data["solved-jumps-percent"] != 1 and data["solved-jumps-percent"] != -1:
                            print(f"[EVMLiSA] {filename} - solved-jumps-percent: {data['solved-jumps-percent']}")
                            sound = False
                    else:
                        print(f"[EVMLiSA] Warning: 'solved-jumps-percent' not found in {filename}")
            except Exception as e:
                print(f"[EVMLiSA] ERROR: {filename}: {e}")
    
    if sound:
        print("[EVMLiSA] All analysis are SOUND")

def get_results_evmlisa(directory_path, print_data):
    warnings_counts = {}
    failed = 0
    
    for filename in os.listdir(directory_path):
        if filename.endswith(".json"):
            file_path = os.path.join(directory_path, filename)
            try:
                with open(file_path, 'r') as file:
                    data = json.load(file)
                    if "re-entrancy-warning" in data:
                        warnings_counts[filename] = data['re-entrancy-warning']
                    elif "tx-origin-warning" in data:
                        warnings_counts[filename] = data['tx-origin-warning']
                    elif "timestamp-dependency-warning" in data:
                        warnings_counts[filename] = data['timestamp-dependency-warning']
                    else:
                        print(f"[EVMLiSA] Warning: 're-entrancy-warning', 'tx-origin-warning' and 'timestamp-dependency-warning' not found in {filename}")
            except Exception as e:
                failed += 1
                # print(f"[EVMLiSA] ERROR: {filename}: {e}")            

    results = defaultdict(int)
    for file, result in warnings_counts.items():
        # solidifi case
        match = re.match(r'buggy_(\d+)-\w+\.json', file)
        if match:
            id = int(match.group(1))
            results[id] += result
        
        match = re.match(r'buggy_(\d+)_(\d+)-\w+\.json', file)
        if match:
            id = int(match.group(1))
            results[id] += result
        
        # smartbug & slise case
        match = re.match(r'(\d+)-\w+\.json', file)
        if match:
            id = int(match.group(1))
            results[id] += result

        match = re.match(r'(\d+)_(\d+)-\w+\.json', file)
        if match:
            id = int(match.group(1))
            results[id] += result

    sorted_data = dict(sorted(results.items()))
    
    print(print_data)
    print(sorted_data)

    return sorted_data

#################################### EtherSolve

def run_ethersolve(bytecode_file, result_ethersolve_dir):
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

def ethersolve(bytecode_dir, result_ethersolve_dir):
    """
    Main function to run EtherSolve analyses on multiple bytecode files.
    """
    delete_files(result_ethersolve_dir)
    os.makedirs(result_ethersolve_dir, exist_ok=True)
    
    # Find all bytecode files
    bytecode_files = [os.path.join(bytecode_dir, f) for f in os.listdir(bytecode_dir) if f.endswith(".bytecode")]
    num_files = len(bytecode_files)
    print(f"[ETHERSOLVE] Found {num_files} bytecode files for analysis.")
    print(f"[ETHERSOLVE] Starting analysis")

    analysis_ended = 0

    # Run analyses in parallel
    with ThreadPoolExecutor(max_workers=1) as executor:
        future_to_file = {executor.submit(run_ethersolve, file, result_ethersolve_dir): file for file in bytecode_files}
        
        with tqdm(total=num_files, desc="[ETHERSOLVE] Analyzing bytecode files") as pbar:
            for future in as_completed(future_to_file):
                result_file = future.result()
                if result_file:
                    # print(f"Analysis complete for {result_file}")
                    analysis_ended += 1
                pbar.update(1)
    print(f"[ETHERSOLVE] Completed {analysis_ended}/{num_files}.")
    delete_tmp_files(bytecode_dir)

def get_results_ethersolve(directory_path, print_data):
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
        # solidifi case
        match = re.match(r'buggy_(\d+)-\w+\.csv', file)
        if match:
            id = int(match.group(1))
            results[id] += result
        
        match = re.match(r'buggy_(\d+)_(\d+)-\w+\.csv', file)
        if match:
            id = int(match.group(1))
            results[id] += result
        
        # smartbugs & slise case
        match = re.match(r'(\d+)-\w+\.csv', file)
        if match:
            id = int(match.group(1))
            results[id] += result

        match = re.match(r'(\d+)_(\d+)-\w+\.csv', file)
        if match:
            id = int(match.group(1))
            results[id] += result
        
    sorted_data = dict(sorted(results.items()))
    
    print(print_data)
    print(sorted_data)
    
    return sorted_data

#################################### SolidiFI

def get_results_solidifi(folder_path, type, print_data):
    # Initialize a dictionary to store the line count for each problem ID
    line_counts = defaultdict(int)

    reentrancy_subtraction_values = {
        11: 1, 12: 9, 18: 1, 20: 2, 21: 4, 22: 7, 29: 3, 33: 3, 36: 7, 37: 1, 42: 3, 48: 1
    }

    txorigin_subtraction_values = {
        11: 1, 12: 9, 18: 1, 20: 2, 21: 4, 22: 7, 29: 3, 33: 3, 36: 7, 37: 1, 42: 3, 48: 1
    }

    timestampdependency_subtraction_values = {
        11: 1, 12: 9, 18: 1, 20: 2, 21: 4, 22: 7, 29: 3, 33: 3, 36: 7, 37: 1, 42: 3, 48: 1
    }

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
            if type == 'reentrancy':
                line_counts[problem_id] = num_lines - 1 - reentrancy_subtraction_values.get(problem_id, 0)
            elif type == 'tx-origin':
                line_counts[problem_id] = num_lines - 1 - txorigin_subtraction_values.get(problem_id, 0)
            elif type == 'timestamp-dependency':
                line_counts[problem_id] = num_lines - 1 - timestampdependency_subtraction_values.get(problem_id, 0)
            

    sorted_data = dict(sorted(line_counts.items()))

    print(print_data)
    print(sorted_data)

    return sorted_data

#################################### smartbugs

def get_results_smartbugs(json_path, print_data):
    """
    Counts the number of vulnerabilities for each Solidity file in the JSON file.
    """
    # Initialize a dictionary to store the vulnerability count for each file
    vulnerability_counts = defaultdict(int)

    # Load JSON data
    with open(json_path, 'r') as file:
        data = json.load(file)
    
    # Iterate over each entry in the JSON data
    for entry in data:
        # Extract the filename without the extension
        file_id = int(os.path.splitext(entry["name"])[0])
        
        # Count the vulnerabilities for the file
        vulnerability_counts[file_id] = len(entry.get("vulnerabilities", []))

    # Sort the data by file ID
    sorted_data = dict(sorted(vulnerability_counts.items()))

    print(print_data)
    print(sorted_data)
    
    return sorted_data

#################################### slise

def get_results_slise(json_path, print_data):
    """
    Counts the number of vulnerabilities for each Solidity file in the JSON file.
    """
    # Initialize a dictionary to store the vulnerability count for each file
    vulnerability_counts = defaultdict(str)

    # Load JSON data
    with open(json_path, 'r') as file:
        data = json.load(file)
    
    # Iterate over each entry in the JSON data
    for entry in data:
        # Extract the filename without the extension
        file_id = str(os.path.splitext(entry["name"])[0])
        
        # Count the vulnerabilities for the file
        vulnerability_counts[file_id] = len(entry.get("vulnerabilities", []))

    # Sort the data by file ID
    sorted_data = dict(sorted(vulnerability_counts.items()))
    sorted_data = map_file_names_to_ids(sorted_data, './reentrancy-slise-db1/match-file-index.json')

    print(print_data)
    print(sorted_data)
    
    return sorted_data

#################################### Statistics
def calculate_precision(data, truth):
    results_with_precision = {}
    
    for key, value in data.items():
        truth_value = truth.get(key) if truth.get(key) is not None else 0
        diff = value - truth_value
        tp = fp = fn = 0

        if diff == 0: # True positive
            tp = value 
        elif diff > 0: # False positive
            fp = diff
            tp = truth_value
        else: # False negative
            fn = diff * (-1)

        precision = tp / (tp + fp) if (tp + fp) != 0 else 0
        results_with_precision[key] = precision

    return results_with_precision

def calculate_recall(data, truth):
    results_with_recall = {}
    
    for key, value in data.items():
        truth_value = truth.get(key) if truth.get(key) is not None else 0
        diff = value - truth_value
        tp = fp = fn = 0

        if diff == 0: # True positive
            tp = value
        elif diff > 0: # False positive
            fp = diff
            tp = truth_value
        else: # False negative
            fn = diff * (-1)
            tp = value

        recall = tp / (tp + fn) if (tp + fn) != 0 else 0
        results_with_recall[key] = recall
    
    return results_with_recall

def calculate_f_measure(precision, recall):
    results_with_f_measure = {}
    
    for key, p in precision.items():
        r = recall.get(key)
        f_measure = 2 * ((p * r) / (p + r)) if (p + r) != 0 else 0
        results_with_f_measure[key] = f_measure
    
    return results_with_f_measure

#################################### Main

if __name__ == "__main__":
    
    parser = argparse.ArgumentParser(description="EVMLiSA and EtherSolve analysis.")
    parser.add_argument("--solidifi", action="store_true", help="Run analysis on SolidiFI dataset")
    parser.add_argument("--smartbugs", action="store_true", help="Run analysis on SmartBugs dataset")
    parser.add_argument("--slise", action="store_true", help="Run analysis on SliSE dataset")
    parser.add_argument("--no-analysis", action="store_true", help="Do not run the analysis, compute only the results")
    parser.add_argument("--reentrancy", action="store_true", help="Run analysis on reentrancy contracts")
    parser.add_argument("--tx-origin", action="store_true", help="Run analysis on tx-origin contracts")
    parser.add_argument("--timestamp-dependency", action="store_true", help="Run analysis on timestamp-dependency contracts")

    args = parser.parse_args()
    
    if not args.no_analysis:
        build_evmlisa()

    if args.tx_origin:
        if args.solidifi:
            if not args.no_analysis:
                evmlisa_thread = threading.Thread(target=evmlisa, kwargs={'bytecode_dir':       './tx-origin-solidifi/bytecode/evmlisa', 
                                                                          'results_dir':        './tx-origin-solidifi/results',
                                                                          'result_evmlisa_dir': './tx-origin-solidifi/results/evmlisa',
                                                                          'type':               'txorigin'})
                evmlisa_vanilla_thread = threading.Thread(target=evmlisa, kwargs={'bytecode_dir':       './vanilla-solidifi/bytecode/evmlisa', 
                                                                                  'results_dir':        './vanilla-solidifi/results',
                                                                                  'result_evmlisa_dir': './vanilla-solidifi/results/evmlisa',
                                                                                  'type':               'txorigin'})
                
                evmlisa_vanilla_thread.start()
                evmlisa_thread.start()
                evmlisa_thread.join()
                evmlisa_vanilla_thread.join()

                check_sound_analysis_evmlisa('./tx-origin-solidifi/results/evmlisa')
                  
            results_solidifi = get_results_solidifi('./SolidiFI-buggy-contracts/tx.origin', 'tx-origin', 'solidify')
            results_evmlisa = subtract_dicts(get_results_evmlisa('./tx-origin-solidifi/results/evmlisa', 'evmlisa-buggy-solidifi'),
                                             get_results_evmlisa('./vanilla-solidifi/results/evmlisa', 'evmlisa-vanilla-solidifi'))
            
            # Precision
            evmlisa_precision = calculate_precision(results_evmlisa, results_solidifi)
            print(f"Precision evmlisa (avg.): {calculate_average(evmlisa_precision)}")

            # Recall
            evmlisa_recall = calculate_recall(results_evmlisa, results_solidifi)
            print(f"Recall evmlisa (avg.): {calculate_average(evmlisa_recall)}")

            # F-measure
            print(f"F-measure evmlisa (avg.): {calculate_average(calculate_f_measure(evmlisa_precision, evmlisa_recall))}")
            
            # Plot results
            plot_results(results_evmlisa, 
                        results_solidifi,
                        'solidifi_tx-origin')

    if args.timestamp_dependency:
        if args.solidifi:
            if not args.no_analysis:
                evmlisa_thread = threading.Thread(target=evmlisa, kwargs={'bytecode_dir':       './timestamp-dependency-solidifi/bytecode/evmlisa',
                                                                          'results_dir':        './timestamp-dependency-solidifi/results',
                                                                          'result_evmlisa_dir': './timestamp-dependency-solidifi/results/evmlisa',
                                                                          'type':               'timestampdependency'})
                evmlisa_vanilla_thread = threading.Thread(target=evmlisa, kwargs={'bytecode_dir':       './vanilla-solidifi/bytecode/evmlisa',
                                                                                  'results_dir':        './vanilla-solidifi/results',
                                                                                  'result_evmlisa_dir': './vanilla-solidifi/results/evmlisa',
                                                                                  'type':               'timestampdependency'})

                evmlisa_vanilla_thread.start()
                evmlisa_thread.start()
                evmlisa_thread.join()
                evmlisa_vanilla_thread.join()

                check_sound_analysis_evmlisa('./timestamp-dependency-solidifi/results/evmlisa')

            results_solidifi = get_results_solidifi('./SolidiFI-buggy-contracts/Timestamp-Dependency', 'timestamp-dependency', 'solidify')
            results_evmlisa = subtract_dicts(get_results_evmlisa('./timestamp-dependency-solidifi/results/evmlisa', 'evmlisa-buggy-solidifi'),
                                             get_results_evmlisa('./vanilla-solidifi/results/evmlisa', 'evmlisa-vanilla-solidifi'))

            # Precision
            evmlisa_precision = calculate_precision(results_evmlisa, results_solidifi)
            print(f"Precision evmlisa (avg.): {calculate_average(evmlisa_precision)}")

            # Recall
            evmlisa_recall = calculate_recall(results_evmlisa, results_solidifi)
            print(f"Recall evmlisa (avg.): {calculate_average(evmlisa_recall)}")

            # F-measure
            print(f"F-measure evmlisa (avg.): {calculate_average(calculate_f_measure(evmlisa_precision, evmlisa_recall))}")

            # Plot results
            plot_results(results_evmlisa,
                         results_solidifi,
                         'solidifi_timestamp-dependency')
        if args.smartbugs:
            evmlisa_thread = threading.Thread(target=evmlisa, kwargs={'bytecode_dir':       './timestamp-dependency-smartbugs/bytecode/evmlisa', 
                                                                        'results_dir':        './timestamp-dependency-smartbugs/results',
                                                                        'result_evmlisa_dir': './timestamp-dependency-smartbugs/results/evmlisa',
                                                                        'type':               'timestampdependency'})
                
            evmlisa_thread.start()
            evmlisa_thread.join()

            check_sound_analysis_evmlisa('./timestamp-dependency-smartbugs/results/evmlisa')

            results_evmlisa = get_results_evmlisa('./timestamp-dependency-smartbugs/results/evmlisa', 'evmlisa-buggy-smartbugs')                        
            results_smartbugs = get_results_smartbugs('./timestamp-dependency-smartbugs/source-code/vulnerabilities.json', 'smartbugs')
            
            # Precision
            evmlisa_precision = calculate_precision(results_evmlisa, results_smartbugs)
            print(f"Precision evmlisa (avg.): {calculate_average(evmlisa_precision)}")

            # Recall
            evmlisa_recall = calculate_recall(results_evmlisa, results_smartbugs)
            print(f"Recall evmlisa (avg.): {calculate_average(evmlisa_recall)}")

            # F-measure
            print(f"F-measure evmlisa (avg.): {calculate_average(calculate_f_measure(evmlisa_precision, evmlisa_recall))}")
            
            # Plot results
            plot_results(results_evmlisa, 
                        results_smartbugs,
                        'smartbugs')

    if args.reentrancy:
        if args.solidifi:
            # SolidiFI dataset
            if not args.no_analysis:
                evmlisa_vanilla_thread = threading.Thread(target=evmlisa, kwargs={'bytecode_dir':       './vanilla-solidifi/bytecode/evmlisa', 
                                                                                  'results_dir':        './vanilla-solidifi/results',
                                                                                  'result_evmlisa_dir': './vanilla-solidifi/results/evmlisa'})
                evmlisa_thread = threading.Thread(target=evmlisa, kwargs={'bytecode_dir':       './reentrancy-solidifi/bytecode/evmlisa', 
                                                                          'results_dir':        './reentrancy-solidifi/results',
                                                                          'result_evmlisa_dir': './reentrancy-solidifi/results/evmlisa'})
                
                ethersolve_thread = threading.Thread(target=ethersolve, kwargs={'bytecode_dir':             './reentrancy-solidifi/bytecode/ethersolve',
                                                                                'result_ethersolve_dir':    './reentrancy-solidifi/results/ethersolve'})
                ethersolve_vanilla_thread = threading.Thread(target=ethersolve, kwargs={'bytecode_dir':             './vanilla-solidifi/bytecode/ethersolve',
                                                                                        'result_ethersolve_dir':    './vanilla-solidifi/results/ethersolve'})
                
                evmlisa_vanilla_thread.start()
                evmlisa_thread.start()
                ethersolve_thread.start()
                
                ethersolve_thread.join()
                evmlisa_vanilla_thread.join()
                evmlisa_thread.join()

                ethersolve_vanilla_thread.start()
                ethersolve_vanilla_thread.join()

                check_sound_analysis_evmlisa('./reentrancy-solidifi/results/evmlisa')
                check_sound_analysis_evmlisa('./vanilla-solidifi/results/evmlisa')
            
            results_evmlisa = subtract_dicts(get_results_evmlisa('./reentrancy-solidifi/results/evmlisa', 'evmlisa-buggy-solidifi'),
                                             get_results_evmlisa('./vanilla-solidifi/results/evmlisa', 'evmlisa-vanilla-solidifi'))
            results_ethersolve = subtract_dicts(get_results_ethersolve('./reentrancy-solidifi/results/ethersolve', 'ethersolve-buggy-solidifi'),
                                                get_results_ethersolve('./vanilla-solidifi/results/ethersolve', 'ethersolve-vanilla-solidifi'))
            results_solidifi = get_results_solidifi('./SolidiFI-buggy-contracts/Re-entrancy', 'reentrancy', 'solidify')
            
            # Precision
            evmlisa_precision = calculate_precision(results_evmlisa, results_solidifi)
            ethersolve_precision = calculate_precision(results_ethersolve, results_solidifi)
            print(f"Precision evmlisa (avg.): {calculate_average(evmlisa_precision)}")
            print(f"Precision ethersolve (avg.): {calculate_average(ethersolve_precision)}")

            # Recall
            evmlisa_recall = calculate_recall(results_evmlisa, results_solidifi)
            ethersolve_recall = calculate_recall(results_ethersolve, results_solidifi)
            print(f"Recall evmlisa (avg.): {calculate_average(evmlisa_recall)}")
            print(f"Recall ethersolve (avg.): {calculate_average(ethersolve_recall)}")

            # F-measure
            print(f"F-measure evmlisa (avg.): {calculate_average(calculate_f_measure(evmlisa_precision, evmlisa_recall))}")
            print(f"F-measure ethersolve (avg.): {calculate_average(calculate_f_measure(ethersolve_precision, ethersolve_recall))}")
            
            # Plot results
            plot_results(results_evmlisa, 
                        results_ethersolve,
                        results_solidifi,
                        'solidifi')
        
        if args.smartbugs:
            # SmartBugs dataset
            if not args.no_analysis:
                evmlisa_thread = threading.Thread(target=evmlisa, kwargs={'bytecode_dir':       './reentrancy-smartbugs/bytecode/evmlisa', 
                                                                        'results_dir':        './reentrancy-smartbugs/results',
                                                                        'result_evmlisa_dir': './reentrancy-smartbugs/results/evmlisa'})
                ethersolve_thread = threading.Thread(target=ethersolve, kwargs={'bytecode_dir':             './reentrancy-smartbugs/bytecode/ethersolve',
                                                                                'result_ethersolve_dir':    './reentrancy-smartbugs/results/ethersolve'})
                
                evmlisa_thread.start()
                ethersolve_thread.start()
                
                ethersolve_thread.join()
                evmlisa_thread.join()

                check_sound_analysis_evmlisa('./reentrancy-smartbugs/results/evmlisa')

            results_evmlisa = get_results_evmlisa('./reentrancy-smartbugs/results/evmlisa', 'evmlisa-buggy-smartbugs')                        
            results_ethersolve = get_results_ethersolve('./reentrancy-smartbugs/results/ethersolve', 'ethersolve-buggy-smartbugs')
            results_smartbugs = get_results_smartbugs('./reentrancy-smartbugs/source-code/vulnerabilities.json', 'smartbugs')
            
            # Precision
            evmlisa_precision = calculate_precision(results_evmlisa, results_smartbugs)
            ethersolve_precision = calculate_precision(results_ethersolve, results_smartbugs)
            print(f"Precision evmlisa (avg.): {calculate_average(evmlisa_precision)}")
            print(f"Precision ethersolve (avg.): {calculate_average(ethersolve_precision)}")

            # Recall
            evmlisa_recall = calculate_recall(results_evmlisa, results_smartbugs)
            ethersolve_recall = calculate_recall(results_ethersolve, results_smartbugs)
            print(f"Recall evmlisa (avg.): {calculate_average(evmlisa_recall)}")
            print(f"Recall ethersolve (avg.): {calculate_average(ethersolve_recall)}")

            # F-measure
            print(f"F-measure evmlisa (avg.): {calculate_average(calculate_f_measure(evmlisa_precision, evmlisa_recall))}")
            print(f"F-measure ethersolve (avg.): {calculate_average(calculate_f_measure(ethersolve_precision, ethersolve_recall))}")
            
            # Plot results
            plot_results(results_evmlisa, 
                        results_ethersolve,
                        results_smartbugs,
                        'smartbugs')
            
        if args.slise:
            # SliSE dataset
            if not args.no_analysis:
                evmlisa_thread = threading.Thread(target=evmlisa, kwargs={'bytecode_dir':       './reentrancy-slise-db1/bytecode/evmlisa', 
                                                                        'results_dir':        './reentrancy-slise-db1/results',
                                                                        'result_evmlisa_dir': './reentrancy-slise-db1/results/evmlisa'})
                ethersolve_thread = threading.Thread(target=ethersolve, kwargs={'bytecode_dir':             './reentrancy-slise-db1/bytecode/ethersolve',
                                                                                'result_ethersolve_dir':    './reentrancy-slise-db1/results/ethersolve'})
                
                evmlisa_thread.start()
                ethersolve_thread.start()
                
                ethersolve_thread.join()
                evmlisa_thread.join()

                check_sound_analysis_evmlisa('./reentrancy-slise-db1/results/evmlisa')

            results_evmlisa = get_results_evmlisa('./reentrancy-slise-db1/results/evmlisa', 'evmlisa-buggy-slise-db1')                        
            results_ethersolve = get_results_ethersolve('./reentrancy-slise-db1/results/ethersolve', 'ethersolve-buggy-slise-db1')
            results_slise = get_results_slise('./reentrancy-slise-db1/source-code/vulnerabilities.json', 'slise-db1')
            
            # Precision
            evmlisa_precision = calculate_precision(results_evmlisa, results_slise)
            ethersolve_precision = calculate_precision(results_ethersolve, results_slise)
            print(f"Precision evmlisa (avg.): {calculate_average(evmlisa_precision)}")
            print(f"Precision ethersolve (avg.): {calculate_average(ethersolve_precision)}")

            # Recall
            evmlisa_recall = calculate_recall(results_evmlisa, results_slise)
            ethersolve_recall = calculate_recall(results_ethersolve, results_slise)
            print(f"Recall evmlisa (avg.): {calculate_average(evmlisa_recall)}")
            print(f"Recall ethersolve (avg.): {calculate_average(ethersolve_recall)}")

            # F-measure
            print(f"F-measure evmlisa (avg.): {calculate_average(calculate_f_measure(evmlisa_precision, evmlisa_recall))}")
            print(f"F-measure ethersolve (avg.): {calculate_average(calculate_f_measure(ethersolve_precision, ethersolve_recall))}")
            
            # Plot results
            plot_results(results_evmlisa, 
                        results_ethersolve,
                        results_slise,
                        'slise')
        