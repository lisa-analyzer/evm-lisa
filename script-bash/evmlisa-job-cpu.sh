#!/bin/bash
#SBATCH --job-name=evmlisa
#SBATCH --output=./messages/%x.o%j
#SBATCH --error=./messages/%x.e%j
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --time=3-00:00:00
#SBATCH --mem=64G
#SBATCH --mail-user=saveriomattia.merenda@studenti.unipr.it 
#SBATCH --mail-type=FAIL
#SBATCH --partition=cpu
#SBATCH --qos=cpu
#SBATCH --account=g_informatica

# ---------------------------------------------

newgrp G_INFORMATICA
module load java/jdk/11.0.3

export _JAVA_OPTIONS=-Xmx64000M

BEN=$1
OUTPUTDIR=$2
SS=$3
SSS=$4

./evm-lisa-binary/evm-lisa/bin/evm-lisa \
-b ./$BEN \
--stack-size $SS \
--stack-set-size $SSS \
--cores 1 \
--output $OUTPUTDIR