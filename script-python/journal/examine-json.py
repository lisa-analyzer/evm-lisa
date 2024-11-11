import os
import json
from tqdm import tqdm

def count_json_and_functions(folder_path, output_file="swc-report.json"):
    json_count = 0
    function_count = 0
    total_files = sum([len(files) for _, _, files in os.walk(folder_path)])  # Conta tutti i file
    report_data = {}  # Dizionario per memorizzare i risultati

    # Barra di avanzamento per il conteggio dei file
    with tqdm(total=total_files, desc="Processing files") as pbar:
        for root, _, files in os.walk(folder_path):
            for file_name in files:
                # Verifica se il file è un JSON
                if file_name.endswith(".json"):
                    json_count += 1
                    file_path = os.path.join(root, file_name)
                    local_function_count = 0  # Conta i "function" diversi da N/A per questo file

                    # Apri e carica il contenuto del file JSON
                    with open(file_path, 'r', encoding='utf-8') as f:
                        data = json.load(f)

                        # Conta i campi "function" diversi da "N/A" nella lista "SWCs"
                        if "SWCs" in data:
                            for swc in data["SWCs"]:
                                if swc.get("function"):# and swc["function"] != "N/A":
                                    local_function_count += 1

                    # Se il conteggio di "function" diversi da N/A è maggiore di zero, aggiungi al report
                    if local_function_count > 0:
                        parent_folder = os.path.basename(root)
                        report_key = f"{parent_folder}/{file_name}"
                        report_data[report_key] = local_function_count

                    # Aggiungi il conteggio locale al conteggio totale
                    function_count += local_function_count
                
                pbar.update(1)  # Aggiorna la barra di avanzamento dopo ogni file

    # Salva il report in formato JSON
    with open(output_file, "w", encoding="utf-8") as out_file:
        json.dump(report_data, out_file, indent=4)

    return json_count, function_count

def count_json(folder_path):
    json_count = 0
    total_files = sum([len(files) for _, _, files in os.walk(folder_path)])  # Conta tutti i file

    # Barra di avanzamento per il conteggio dei file
    with tqdm(total=total_files, desc="Processing files") as pbar:
        for root, _, files in os.walk(folder_path):
            for file_name in files:
                # Verifica se il file è un JSON
                if file_name.endswith(".json"):
                    json_count += 1
                    file_path = os.path.join(root, file_name)

                pbar.update(1)  # Aggiorna la barra di avanzamento dopo ogni file

    return json_count

folder_path = "./DAppSCAN/DAppSCAN-bytecode/SWCbytecode/"
json_count, function_count = count_json_and_functions(folder_path)
print(f"Number of JSON files: {json_count}")
print(f"Number of vulnerabilities: {function_count}")

folder_path = "./DAppSCAN/DAppSCAN-bytecode/bytecode/"
json_count = count_json(folder_path)
print(f"Number of JSON files: {json_count}")
