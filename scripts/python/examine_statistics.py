import csv
import argparse

def calculate_statistics(file_path):
    
    total_opcodes = 0
    total_jumps = 0
    resolved_jumps = 0
    unknown_jumps = 0
    unreachable_jumps = 0
    erroneous_jumps = 0
    edges = 0
    time_millis = 0
    rows = 0

    with open(file_path, newline='') as csvfile:
        reader = csv.reader(csvfile)
        
        header = next(reader)
        
        total_opcodes_index = header.index(" Total Opcodes")
        total_jumps_index = header.index(" Total Jumps")
        resolved_jumps_index = header.index(" Resolved Jumps")
        unknown_jumps_index = header.index(" Unknown jumps")
        unreachable_jumps_index = header.index(" Unreachable jumps")
        erroneous_jumps_index = header.index(" Erroneous Jumps")
        edges_index = header.index(" Edges")
        time_millis_index = header.index(" Time (millis)")

        for row in reader:
            rows += 1
            total_opcodes += int(row[total_opcodes_index])
            total_jumps += int(row[total_jumps_index])
            resolved_jumps += int(row[resolved_jumps_index])
            unknown_jumps += int(row[unknown_jumps_index])
            unreachable_jumps += int(row[unreachable_jumps_index])
            erroneous_jumps += int(row[erroneous_jumps_index])
            edges += int(row[edges_index])
            time_millis += int(row[time_millis_index])

    avg_time_millis = time_millis / rows if rows else None
    classified = resolved_jumps + unknown_jumps + unreachable_jumps + erroneous_jumps

    print(f"Smart contracts examined: {rows}")
    print(f"Total Opcodes: {total_opcodes}")
    print(f"Total Jumps: {total_jumps}")
    print(f"Resolved Jumps: {resolved_jumps} ({percentuale(resolved_jumps,total_jumps)}%)")
    print(f"Unknown jumps: {unknown_jumps} ({percentuale(unknown_jumps,total_jumps)}%)")
    print(f"Unreachable jumps: {unreachable_jumps} ({percentuale(unreachable_jumps,total_jumps)}%)")
    print(f"Erroneous jumps: {erroneous_jumps} ({percentuale(erroneous_jumps,total_jumps)}%)")
    print(f"Total jumps with classification: {classified} ({'match' if classified == total_jumps else 'mismatch'})")
    print(f"Edges: {edges}")
    print(f"Average Time (seconds): {avg_time_millis / 1000}")

def percentuale(num, den):
    if num is None or den is None or den == 0:
        return "N/A"
    percentuale_str = "{:.4f}%".format((num/den) * 100)
    return percentuale_str

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Calculate statistics.")
    parser.add_argument(
        "--input", 
        nargs='+', 
        required=True, 
        help="Path(s) of the input file(s)"
    )

    args = parser.parse_args()

    for file_path in args.input:
        print(f"Calculating statistics for {file_path}")
        calculate_statistics(file_path)
        print()

