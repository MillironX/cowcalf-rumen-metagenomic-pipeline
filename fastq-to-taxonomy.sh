#!/bin/bash
#SBATCH --account=ACCOUNT
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=4
#SBATCH --cpus-per-task=4
#SBATCH --mem=16000
#SBATCH --time="2-00:00:00"

module restore system
module load metaxa2
module load blast-legacy

R1filename=${1%}
R2filename="${R1filename/R1/R2}"
Samplename="${R1filename/_R1_001.fastq.gz/}"
Samplename="${Samplename/\.\//}"

# Extract rRNA to files
metaxa2 -1 "$R1filename" -2 "$R2filename" -o "$Samplename" -f q -cpu 4 \
 --summary F --graphical F --fasta F --taxonomy T

# Switch modes to extract taxonomy
INPUT2="${Samplename}.taxonomy.txt"

# Compile the taxonomy
metaxa2_ttt -i "$INPUT2" -o "$Samplename" -cpu4 -m 7 -n 7 --summary F