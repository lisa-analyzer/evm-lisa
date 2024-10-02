"""
This script analyzes the files in a specified directory and counts how many times each line preceding
the appearance of "JUMP" or "JUMPI" appears in the files. A separate count is done for instructions 
of type "PUSH," "LOG," "SWAP," and "DUP," excluding lines containing the word "Unknown." 
The result of the count is printed on the screen.
"""

import os

global pushed_jumps
pushed_jumps = 0
global orphan_jumps
orphan_jumps = 0

def find_previous_jump_line(file_path, jump_line_counter):
    with open(file_path, 'r', encoding='utf-8') as file:
        lines = file.readlines()
        for i in range(1, len(lines)):
            if ('JUMP' in lines[i] or 'JUMPI' in lines[i]) and ('JUMPDEST' not in lines[i]):
                previous_line = lines[i - 1].strip()
                    
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

                if previous_line == 'PUSH':
                    global pushed_jumps
                    pushed_jumps += 1
                else:
                    global orphan_jumps
                    orphan_jumps += 1

def get_name(file_path):
    return os.path.splitext(os.path.basename(file_path))[0]

if __name__ == "__main__":
    directory_path = "../ground-truth-stats/test/benchmark"
    output_file = "results-opcodes-preceding-a-jump.txt"

    file_counter = 0
    jump_line_counter = {}
    
    for root, dirs, files in os.walk(directory_path):
        for file in files:
            if file.endswith('.sol'):
                file_path = os.path.join(root, file)
                find_previous_jump_line(file_path, jump_line_counter)
                file_counter += 1
    
    with open(output_file, 'w', encoding='utf-8') as output:
        print(f"Opcode precedenti a 'JUMP' o 'JUMPI' in {file_counter} bytecode esaminati:")
        for line, count in jump_line_counter.items():
            print(f"{line}: {count}")
            # output.write(line + '\n')

        print(f"Pushed jumps: {pushed_jumps}")
        print(f"Orphan jumps: {orphan_jumps}")