"""
Questo script esplora ricorsivamente una directory specificata dall'utente e 
analizza ogni file al suo interno. Per ogni file che soddisfa determinate condizioni 
(meno di 3000 righe), salva il nome del file 
(senza estensione) in un file di output specificato.
"""
import os


def analyze_file(file_path):
    try:
        with open(file_path, 'r', encoding='utf-8') as file:
            lines = file.readlines()
            if len(lines) < 3000:
                return True
            else:
                return False
    except Exception as e:
        print(f"Errore nell'analisi del file {file_path}: {e.__class__.__name__} - {e}")
        return False


def explore_directory(directory_path, output_file):
    with open(output_file, 'w', encoding='utf-8') as output:
        for root, dirs, files in os.walk(directory_path):
            print(dirs)
            for file in files:
                file_path = os.path.join(root, file)
                if analyze_file(file_path):
                    output.write(os.path.splitext(file)[0] + '\n')
                    print(os.path.splitext(file)[0] + '\n')


if __name__ == "__main__":
    directory_path = "../execution/results/benchmark/"
    output_file = "less_than_3000_opcode.txt"

    explore_directory(directory_path, output_file)
    print("Esplorazione completata. Risultati salvati in:", output_file)
