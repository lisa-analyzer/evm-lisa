import os
import subprocess
import threading
from concurrent.futures import ThreadPoolExecutor, as_completed
from tqdm import tqdm

# Directory paths
bytecode_dir = './reentrancy/bytecode'
results_dir = './reentrancy/results'
result_evmlisa_dir = results_dir + '/evmlisa'
result_ethersolve_dir = results_dir + '/ethersolve'
max_threads = os.cpu_count() - 3  # Core avaiable

#################################### Utility
def delete_tmp_files(directory):
    """
    Deletes files in the specified directory that contain 'opcodes' in their name.

    Args:
        directory (str): The path to the directory from which to delete files.
    """
    try:
        for filename in os.listdir(directory):
            if 'opcodes' in filename:
                file_path = os.path.join(directory, filename)
                os.remove(file_path)
                # print(f"Deleted: {file_path}")
    except Exception as e:
        print(f"An error occurred: {e}")

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
        f"--stack-set-size 10 "
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
    delete_tmp_files(bytecode_dir)

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
        f"{bytecode_file} "
        f"--json --creation "
        f"--re-entrancy "
        f"-o {result_filepath} 2> /dev/null && "
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

def count_sstore_occurrences(directory_path):
    """
    Counts occurrences of the word "SSTORE" in files with "reentrancy" in their names 
    within the specified directory.

    Args:
        directory_path (str): The path to the directory containing files to search.
    """
    for filename in os.listdir(directory_path):
        # Verifica se il file contiene "reentrancy" nel nome
        if "reentrancy" in filename:
            file_path = os.path.join(directory_path, filename)
            if os.path.isfile(file_path):
                with open(file_path, 'r') as file:
                    content = file.read()
                
                # Conta le occorrenze di "SSTORE"
                sstore_count = content.count("SSTORE")
                
                # Stampa il risultato per il file
                print(f"{filename}: {sstore_count}")

#################################### Main

if __name__ == "__main__":
    evmlisa_thread = threading.Thread(target=evmlisa)
    ethersolve_thread = threading.Thread(target=ethersolve)
    
    evmlisa_thread.start()
    ethersolve_thread.start()

    evmlisa_thread.join()
    ethersolve_thread.join()

    print("Finished")
    clean_files(result_evmlisa_dir)

    # TODO print of results
    count_sstore_occurrences(result_ethersolve_dir)