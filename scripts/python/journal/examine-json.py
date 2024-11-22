import os
import json
from tqdm import tqdm

def count_json_and_functions(folder_path, output_file="swc-report.json"):
    json_count = 0
    function_count = 0
    total_files = sum([len(files) for _, _, files in os.walk(folder_path)]) 
    report_data = {}  

    with tqdm(total=total_files, desc="Processing files") as pbar:
        for root, _, files in os.walk(folder_path):
            for file_name in files:
                if file_name.endswith(".json"):
                    json_count += 1
                    file_path = os.path.join(root, file_name)
                    local_function_count = 0 

                    with open(file_path, 'r', encoding='utf-8') as f:
                        data = json.load(f)

                        if "SWCs" in data:
                            for swc in data["SWCs"]:
                                if swc.get("function"):# and swc["function"] != "N/A":
                                    local_function_count += 1

                    if local_function_count > 0:
                        parent_folder = os.path.basename(root)
                        report_key = f"{parent_folder}/{file_name}"
                        report_data[report_key] = local_function_count

                    function_count += local_function_count
                
                pbar.update(1)

    with open(output_file, "w", encoding="utf-8") as out_file:
        json.dump(report_data, out_file, indent=4)

    return json_count, function_count

def count_json(folder_path):
    json_count = 0
    total_files = sum([len(files) for _, _, files in os.walk(folder_path)])

    with tqdm(total=total_files, desc="Processing files") as pbar:
        for root, _, files in os.walk(folder_path):
            for file_name in files:
                
                if file_name.endswith(".json"):
                    json_count += 1
                    file_path = os.path.join(root, file_name)

                pbar.update(1)

    return json_count

folder_path = "./DAppSCAN/DAppSCAN-bytecode/SWCbytecode/"
json_count, function_count = count_json_and_functions(folder_path)
print(f"Number of JSON files: {json_count}")
print(f"Number of vulnerabilities: {function_count}")

folder_path = "./DAppSCAN/DAppSCAN-bytecode/bytecode/"
json_count = count_json(folder_path)
print(f"Number of JSON files: {json_count}")
