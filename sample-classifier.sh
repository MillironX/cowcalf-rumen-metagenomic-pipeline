#!/bin/bash
#SBATCH --account=cowusda2016
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G

# Fetch the category we're working with from upstream
CATEGORY=${1%}

# Save the folder name we will be saving everything into
FOLDERNAME="${CATEGORY}-classifier"

# Load the required modules
module restore system
module load swset
module load miniconda3

# Start up qiime
source activate qiime2

# Make sure we have a clean slate to work with
echo "--^-- X: Clearing previous classifier results..."
rm -r "$FOLDERNAME"
echo "--^-- X: Clearing previous classifier results...Done!"

# Solve the model
echo "--^-- X: Constructing model..."
qiime sample-classifier classify-samples \
 --i-table feature-table.qza \
 --m-metadata-file metadata.tsv \
 --m-metadata-column "$CATEGORY" \
 --p-n-jobs 4 \
 --p-missing-samples ignore \
 --p-optimize-feature-selection \
 --output-dir "$FOLDERNAME" \
 --verbose
echo "--^-- X: Constructing model...Done!"

# Convert the model output into readable visualizations
echo "--^-- X: Making visualizations..."
qiime metadata tabulate \
 --m-input-file "${FOLDERNAME}/feature_importance.qza" \
 --o-visualization "${FOLDERNAME}/feature-importance.qzv"

qiime metadata tabulate \
 --m-input-file "${FOLDERNAME}/predictions.qza" \
 --m-input-file metadata.tsv \
 --o-visualization "${FOLDERNAME}/predictions.qzv"
echo "--^-- X: Making visualizations...Done!"