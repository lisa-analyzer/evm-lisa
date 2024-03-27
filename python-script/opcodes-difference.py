"""
Questo script Python confronta due file di testo e stampa le righe presenti solo nel primo file.
"""

def file_difference(file1_path, file2_path):
    with open(file1_path, 'r', encoding='utf-8') as file1:
        content1 = set(file1.readlines())

    with open(file2_path, 'r', encoding='utf-8') as file2:
        content2 = set(file2.readlines())

    difference = content1 - content2

    for line in difference:
        print(line.strip())

if __name__ == "__main__":
    file1_path = "all-opcodes.txt"
    file2_path = "results-opcodes-preceding-a-jump.txt"

    file_difference(file1_path, file2_path)
