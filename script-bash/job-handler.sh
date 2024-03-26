#!/bin/bash
#SBATCH --output=./messages/%x.o%j
#SBATCH --error=./messages/%x.e%j
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --time=0-06:00:00
#SBATCH --mem=16G
#SBATCH --mail-user=saveriomattia.merenda@studenti.unipr.it 
#SBATCH --mail-type=FAIL
#SBATCH --partition=cpu
#SBATCH --qos=cpu

# ---------------------------------------------

# File contenente il benchmark
BEN=benchmark/277-soap-benchmark.txt

# Stack Size
SS=128
# Stack Set Size
SSS=128
# Numero di job / numero di sotto-benchmark
N=140

# Parametri da non modificare
COMMON=/hpc/group/G_INFORMATICA/common/evmlisa
DIR=exec-ss$SS-sss$SSS
OUTPUTDIR=$COMMON/$DIR
SPLITTED_DIR=benchmark/splitted

# Splitto il benchmark in N sotto-benchmark
python3 file-splitter.py $BEN $SPLITTED_DIR $N

echo "Please wait 90 seconds (copying smart contracts...)"

# Copio gli smart contracts nella cartella di destinazione
mkdir -p $OUTPUTDIR/benchmark
cp -r ./smart-contract/. $OUTPUTDIR/benchmark

# Inverti l'ordine dei file nella directory di input
files=("$SPLITTED_DIR"/*)
files=($(printf "%s\n" "${files[@]}" | sort -r))

# Variabile di controllo per alternare l'esecuzione dei comandi
toggle=0

# Esegui un job per ogni file di benchmark nella directory di input
for file in "${files[@]}"; do
    if [ $toggle -eq 0 ]; then
        sbatch evmlisa-job-cpu.sh $file $OUTPUTDIR $SS $SSS
        toggle=1
        echo "Job submitted to cpu"
    else
        sbatch evmlisa-job-cpu_guest.sh $file $OUTPUTDIR $SS $SSS
        toggle=0
        echo "Job submitted to cpu_guest"
    fi
    sleep 10
done