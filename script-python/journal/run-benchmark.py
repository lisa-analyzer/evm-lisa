import os
import subprocess
import threading
from concurrent.futures import ThreadPoolExecutor, as_completed
from tqdm import tqdm

# Directory paths
bytecode_dir = './reentrancy/bytecode'
results_dir = './reentrancy/results'
max_threads = os.cpu_count() - 3  # Core avaiable

def build_evmlisa():
    print("Building EVMLiSA...")
    command = (
        f"cd ../../ && "
        f"./gradlew build 2> /dev/null && "
        f"./gradlew distZip > /dev/null 2> /dev/null && "
        f"unzip -o build/distributions/evm-lisa.zip -d script-python/journal/execution > /dev/null"
    )
    subprocess.run(command, shell=True, check=True)
    print("EVMLiSA built successfully.")

def run_analysis(bytecode_file):
    """
    Runs the EVMLiSA analysis for a given bytecode file.
    
    Args:
        bytecode_file (str): The path to the bytecode file.
        
    Returns:
        str: The name of the results file.
    """
    bytecode_filename = os.path.basename(bytecode_file)
    result_filename = f"{os.path.splitext(bytecode_filename)[0]}-result.json"
    result_filepath = os.path.join(results_dir, result_filename)
    
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
        print(f"Error analyzing {bytecode_file}: {e}")
        return None
    
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

def main():
    """
    Main function to run EVMLiSA analyses on multiple bytecode files.
    """
    # Create results directory if it doesn't exist
    os.makedirs(results_dir, exist_ok=True)

    # Build EVMLiSA
    build_evmlisa()
    
    # Find all bytecode files
    bytecode_files = [os.path.join(bytecode_dir, f) for f in os.listdir(bytecode_dir) if f.endswith(".bytecode")]
    num_files = len(bytecode_files)
    print(f"Found {num_files} bytecode files for analysis.")
    print(f"Starting {max_threads} parallels analysis")

    analysis_ended = 0

    # Run analyses in parallel
    with ThreadPoolExecutor(max_workers=max_threads) as executor:
        future_to_file = {executor.submit(run_analysis, file): file for file in bytecode_files}
        
        with tqdm(total=num_files, desc="Analyzing bytecode files") as pbar:
            for future in as_completed(future_to_file):
                result_file = future.result()
                if result_file:
                    # print(f"Analysis complete for {result_file}")
                    analysis_ended += 1
                pbar.update(1)
    print(f"Completed {analysis_ended}/{num_files}.")
    delete_tmp_files(bytecode_dir)

if __name__ == "__main__":
    main()