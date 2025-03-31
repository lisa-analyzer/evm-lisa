#!/bin/bash
#SBATCH --job-name=xEVMLiSA
#SBATCH --output=./messages/%x.o%j
#SBATCH --error=./messages/%x.e%j
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=33
#SBATCH --time=1-12:00:00
#SBATCH --mem=48G
#SBATCH --mail-user=<email> 
#SBATCH --mail-type=ALL
#SBATCH --partition=cpu
#SBATCH --qos=cpu
#SBATCH --account=g_informatica

# ---------------------------------------------

newgrp G_INFORMATICA
module load java/jdk/11.0.3

export _JAVA_OPTIONS=-Xmx47000M

java -jar build/libs/evm-lisa-all.jar --cross-chain