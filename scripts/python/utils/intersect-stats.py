import csv
import os

# Function to read CSV file into a dictionary with specified key columns
def read_csv_to_dict(file_path, key_columns):
    data_dict = {}
    with open(file_path, newline='', encoding='utf-8') as csvfile:
        reader = csv.DictReader(csvfile)
        for row in reader:
            key = tuple(row[col] for col in key_columns)
            data_dict[key] = row
    return data_dict

# Function to intersect dictionaries based on specified key columns and write result to new CSV file
def intersect_and_write_csv(file_path1, file_path2, output_file_path, key_columns, compare_columns):
    data1 = read_csv_to_dict(file_path1, key_columns)
    data2 = read_csv_to_dict(file_path2, key_columns)

    with open(output_file_path, 'w', newline='', encoding='utf-8') as csvfile:
        # Determine the fieldnames for the output file
        fieldnames = key_columns + [f"{col} (File 1)" for col in compare_columns] + [f"{col} (File 2)" for col in compare_columns]
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        writer.writeheader()

        # Iterate over the keys in the first dictionary
        for key in data1:
            if key in data2:
                row = {col: key[i] for i, col in enumerate(key_columns)}

                equals = False
                for col in compare_columns:
                    file1_value = data1[key].get(col, 'N/A')
                    file2_value = data2[key].get(col, 'N/A')
                    
                    if file1_value == file2_value:
                        equals = True
                        
                        row[f"{col} (File 1)"] = file1_value # Da commentare per avere solo l'address nel risultato
                        row[f"{col} (File 2)"] = file2_value # Da commentare per avere solo l'address nel risultato
                    else:
                        equals = False
                        break
                
                if equals:
                    writer.writerow(row)

# Parameters
file_path1 = "stats/statistics-notjumpdest-128-32.csv"
file_path2 = "stats/statistics-numeric-128-32.csv"
output_file_path = "intersection_results.csv"  # Save output file in the current working directory
key_columns = ["Smart Contract"]  # Columns to use for intersection
compare_columns = [" Unsound jumps", " Maybe unsound jumps", " Maybe unreachable jumps"]  # Columns to compare and write in the output

# Run the function to generate the output file
intersect_and_write_csv(file_path1, file_path2, output_file_path, key_columns, compare_columns)

print("Intersection completed. Results saved in:", output_file_path)
