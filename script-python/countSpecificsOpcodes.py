import os

def count_invalid_occurrences(folder_path, output_file):
    # Lista dei file nella cartella
    files = os.listdir(folder_path)

    # Apri il file di output in modalità scrittura
    with open(output_file, 'w') as output:
        output.write(f"Address, Opcodes, # INVALID, # Unknown \n")
        # print(f"Address, Opcodes, # INVALID, # Unknown ")

        file_counter = len(files)

        # Loop attraverso ogni file
        for file_name in files:
            file_path = os.path.join(folder_path, file_name)
            
            # Ignora le directory
            if os.path.isdir(file_path):
                continue
            
            # Contatore per le occorrenze di "INVALID" nel file
            invalid_count = 0
            # Contatore per le occorrenze di "Unknown" nel file
            unknown_count = 0
            # Contatore che tiene traccia delle righe di un file (numero di opcodes)
            total_lines = 0
            
            # Apri il file e controlla le occorrenze di "INVALID"
            with open(file_path, 'r') as file:
                for line in file:
                    total_lines += 1
                    invalid_count += line.count("INVALID")
                    unknown_count += line.count("Unknown")
            
            # Ottieni solo il nome del file senza estensione
            file_name_only = os.path.splitext(file_name)[0]

            # Scrivi il risultato nel file di output
            output.write(f"{file_name_only}, {total_lines}, {invalid_count}, {unknown_count}\n")
            # print(f"{file_name_only}, {total_lines}, {invalid_count}, {unknown_count}")

            file_counter -= 1
            print(f"Rimanenti: {file_counter}")

# Cartella contenente gli smart contract
folder_path = "./allSmartContracts"
# Percorso del file di output
output_file = "./risultati.xls"

count_invalid_occurrences(folder_path, output_file)
