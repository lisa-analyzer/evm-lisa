import csv

# Percorso del file CSV
file_path = "statistics-128-256.csv"
file_path2 = "statistics-200-150.csv"

def calculate_statistics(file_path):
    # Lista per memorizzare i valori delle colonne
    total_solved_values = 0
    time_millis_values = 0
    total_jumps_values = 0
    total_solved_jumps_values = 0
    precisely_solved_jumps = 0
    sound_solved_jumps = 0
    definitely_unreachable_jumps = 0
    maybe_unreachable_jumps = 0
    rows = 0

    # Apri il file CSV in modalità lettura
    with open(file_path, newline='') as csvfile:
        reader = csv.reader(csvfile)
        
        # Leggi l'intestazione
        header = next(reader)
        
        # Trova gli indici delle colonne
        total_solved_index = header.index(" % Total Solved")
        time_millis_index = header.index(" Time (millis)")
        total_jumps_index = header.index(" Total Jumps")
        total_solved_jumps_index = header.index(" Total solved Jumps")
        precisely_solved_jumps_index = header.index(" Precisely solved Jumps")
        sound_solved_jumps_index = header.index(" Sound solved Jumps")
        definitely_unreachable_jumps_index = header.index(" Definitely unreachable jumps")
        maybe_unreachable_jumps_index = header.index(" Maybe unreachable jumps")

        # Leggi le righe rimanenti
        for row in reader:
            rows += 1
            # Aggiungi i valori alle rispettive liste
            if(float(row[total_solved_index]) != float(-1)):
                total_solved_values += float(row[total_solved_index])
            time_millis_values += int(row[time_millis_index])
            total_jumps_values += int(row[total_jumps_index])
            total_solved_jumps_values += int(row[total_solved_jumps_index])
            precisely_solved_jumps += int(row[precisely_solved_jumps_index])
            sound_solved_jumps += int(row[sound_solved_jumps_index])
            definitely_unreachable_jumps += int(row[definitely_unreachable_jumps_index])
            maybe_unreachable_jumps += int(row[maybe_unreachable_jumps_index])

    # Calcola le statistiche
    avg_total_solved = total_solved_values / rows if rows else None
    avg_time_millis = time_millis_values / rows if rows else None
    sum_total_jumps = total_jumps_values
    sum_total_solved_jumps = total_solved_jumps_values
    total_solved_jumps_percent = (precisely_solved_jumps + sound_solved_jumps) / total_jumps_values
    total_unsolved_jumps_percent = (definitely_unreachable_jumps + maybe_unreachable_jumps) / total_jumps_values
    total_missed_jumps = sum_total_jumps - (precisely_solved_jumps + sound_solved_jumps + definitely_unreachable_jumps + maybe_unreachable_jumps)
    total_missed_jumps_percent = total_missed_jumps / total_jumps_values
    
    # Stampa dei risultati
    print(f"Smart contract examined: {rows}")
    print(f"Total Jumps: {sum_total_jumps}")
    print(f"Missed Jumps: {total_missed_jumps}")
    print(f"Precisely solved Jumps: {precisely_solved_jumps}")
    print(f"Sound solved Jumps: {sound_solved_jumps}")
    print(f"Definitely unreachable jumps: {definitely_unreachable_jumps}")
    print(f"Maybe unreachable jumps: {maybe_unreachable_jumps}")
    print(f"Total reachable jumps (%): {percentuale(total_solved_jumps_percent)}")
    print(f"Total unreachable jumps (%): {percentuale(total_unsolved_jumps_percent)}")
    print(f"Total unsolved jumps (%): {percentuale(total_missed_jumps_percent)}")
    print(f"Total solved jumps (%): {percentuale(1 - total_missed_jumps_percent)}")
    print(f"Avg execution time (seconds): {avg_time_millis / 1000}")


def percentuale(numero_decimale):
    percentuale_str = "{:.4f}%".format(numero_decimale * 100)
    return percentuale_str


if __name__ == "__main__":
    print("Stack.size: 128 Stack-set.size: 256")
    calculate_statistics(file_path)
    print()
    print("Stack.size: 200 Stack-set.size: 150")
    calculate_statistics(file_path2)
