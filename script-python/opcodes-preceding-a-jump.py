"""
Questo script analizza i file presenti in una directory specificata e conta quante volte ciascuna riga precedente
alla comparsa di "JUMP" o "JUMPI" appare nei file. Viene effettuato un conteggio separato per le istruzioni di tipo
"PUSH", "LOG", "SWAP" e "DUP", escludendo quelle righe che contengono la parola "Unknown". Il risultato del conteggio
viene stampato a schermo.
"""

import os

def find_previous_jump_line(file_path, jump_line_counter):
    with open(file_path, 'r', encoding='utf-8') as file:
        lines = file.readlines()
        for i in range(1, len(lines)):
            if ('JUMP' in lines[i] or 'JUMPI' in lines[i]) and ('JUMPDEST' not in lines[i]):
                previous_line = lines[i - 1].strip()

                if previous_line.startswith('SSTORE'):
                    previous_line = lines[i - 3].strip()
                if previous_line.startswith('MSTORE'):
                    previous_line = lines[i - 3].strip()
                
                if previous_line.startswith('PUSH'):
                    previous_line = 'PUSH'
                if previous_line.startswith('LOG'):
                    previous_line = 'LOG'
                if previous_line.startswith('SWAP'):
                    previous_line = 'SWAP'
                if previous_line.startswith('DUP'):
                    previous_line = 'DUP'
                if 'Unknown' in previous_line:
                    continue
                if previous_line in jump_line_counter:
                    jump_line_counter[previous_line] += 1
                else:
                    jump_line_counter[previous_line] = 1

if __name__ == "__main__":
    directory_path = "../evm-testcases/benchmark"
    output_file = "results-opcodes-preceding-a-jump.txt"

    # Conta quante volte ogni riga precedente a "JUMP" o "JUMPI" appare nei file
    jump_line_counter = {}
    for root, dirs, files in os.walk(directory_path):
        for file in files:
            if file.endswith('.sol'):  # Controllo sull'estensione del file
                file_path = os.path.join(root, file)
                find_previous_jump_line(file_path, jump_line_counter)
    
    with open(output_file, 'w', encoding='utf-8') as output:
        print("Opcode precedenti a 'JUMP' o 'JUMPI':")
        for line, count in jump_line_counter.items():
            print(f"{line}: {count}")
            output.write(line + '\n')