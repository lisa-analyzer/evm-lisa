import os

def find_files_with_invalid_string(folder_path, output_file):
    # Apre il file di output in modalità scrittura
    with open(output_file, 'w') as output:
        # Scansiona tutti i file nella cartella
        for filename in os.listdir(folder_path):
            # Path completo del file
            file_path = os.path.join(folder_path, filename)
               
            # Apre il file in modalità lettura
            with open(file_path, 'r') as file:
                # Legge tutte le righe del file
                lines = file.readlines()
                
                # Verifica se ci sono almeno due righe nel file
                if len(lines) >= 2:
                    # Controlla la penultima riga per la presenza della stringa "INVALID"
                    if "INVALID" in lines[-1]:
                        # Scrive il nome del file nel file di output
                        file_name_only = os.path.splitext(filename)[0]
                        output.write(file_name_only + '\n')

# Cartella contenente gli smart contract
folder_path = "./allSmartContracts"

# Percorso del file di output
output_file = "./smart_contracts_with_invalid_as_last_opcode.txt"

# Trova e scrive i nomi dei file con la stringa "INVALID" nella penultima riga
find_files_with_invalid_string(folder_path, output_file)
