#!/bin/bash
#SBATCH --account=ACCOUNT
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G

# Fetch the category we're working with from upstream
CATEGORY=${1%}

# Save the folder name we will be saving everything into
FOLDERNAME="${CATEGORY}-regression"

# Load the required modules
module restore system
module load swset
module load miniconda3

# Start up qiime
# This code creates errors if run through shellcheck because
# the shellcheck program doesn't understand miniconda:
# We'll add a directive to tell it to ignore this error
# shellcheck disable=SC1091
source activate qiime2

# Make sure we have a clean slate to work with
echo "--^-- X: Creating regression model for ${CATEGORY}"
echo "--^-- X: Clearing previous regression results..."
rm -r "$FOLDERNAME"
echo "--^-- X: Clearing previous regression results...Done!"

# Solve the model
echo "--^-- X: Constructing model..."
qiime sample-classifier regress-samples \
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