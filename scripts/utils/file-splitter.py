"""
Questo script Python prende in input un file di testo e lo divide in un numero specificato di file, ognuno contenente un numero approssimativamente uguale di righe.
I file divisi vengono salvati in una cartella di output, creata automaticamente se non esiste già. Il nome dei file divisi è composto dal nome del file di input seguito da un numero progressivo.
"""
import os
import sys
import shutil

def split_file(input_file, output_dir, num_files):
    with open(input_file, 'r') as f:
        lines = f.readlines()

    lines_per_file = len(lines) // num_files
    remainder = len(lines) % num_files

    if os.path.exists(output_dir):
        # Elimina il contenuto della directory di output se esiste già
        shutil.rmtree(output_dir)

    os.makedirs(output_dir, exist_ok=True)  # Creazione della cartella di output se non esiste

    start = 0
    for i in range(1, num_files + 1):
        end = start + lines_per_file + (1 if i <= remainder else 0)
        output_file = os.path.join(output_dir, f"{os.path.splitext(os.path.basename(input_file))[0]}-{i}.txt")
        with open(output_file, 'w') as f:
            f.writelines(lines[start:end])
        start = end

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: python file-splitter.py <input_file> <output_dir> <num_files>")
        sys.exit(1)

    input_file = sys.argv[1]
    output_dir = sys.argv[2]
    num_files = int(sys.argv[3])

    split_file(input_file, output_dir, num_files)
    # print(f"Il file '{input_file}' è stato diviso in {num_files} file nella directory '{output_dir}'.")
