"""
Questo script esplora ricorsivamente una directory specificata dall'utente e 
analizza ogni file al suo interno. Per ogni file che soddisfa determinate condizioni 
(meno di 3000 righe e non contiene la parola "PUSH0"), salva il nome del file 
(senza estensione) in un file di output specificato.
"""
import os

def analyze_file(file_path):
    try:
        with open(file_path, 'r', encoding='utf-8') as file:
            lines = file.readlines()
            if len(lines) < 3000 and "PUSH0" not in "".join(lines):
                return True
            else:
                return False
    except Exception as e:
        print(f"Error analyzing file {file_path}: {e}")
        return False

def explore_directory(directory_path, output_file):
    with open(output_file, 'w', encoding='utf-8') as output:
        for root, dirs, files in os.walk(directory_path):
            for file in files:
                file_path = os.path.join(root, file)
                if analyze_file(file_path):
                    output.write(os.path.splitext(file)[0] + '\n')

if __name__ == "__main__":
    directory_path = "../evm-testcases/benchmark"
    output_file = "result.txt"

    explore_directory(directory_path, output_file)
    print("Exploration completed. Results saved in:", output_file)
