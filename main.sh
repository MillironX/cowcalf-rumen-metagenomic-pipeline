#!/bin/bash
#SBATCH --account=ACCOUNT
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --ntasks=32
#SBATCH --time="3-00:00:00"

# DEPENDENCIES:
# fastq-to-taxonomy.sh
# manipulatefeaturetable.R
# fetchmetadata.R

# Modules to load
module load swset
module load gcc
module load miniconda3
module load metaxa2
module load r

# Generate Level-7 taxonomy summaries for all samples using paired-end
# read FASTQ files in Metaxa2
# This step can be executed in parallel for all the files, but since
# Metaxa2 uses 4 cpus, we need to make sure that each instance has
# enough cpus to run
echo "--^-- X: Reading FASTQ sequences..."
find . -maxdepth 1 -print0 -name "*R1_001.fastq.gz" | \
  xargs -0 -L1 -P"$SLURM_NTASKS" srun -n1 -N1 --exclusive ./fastq-to-taxonomy.sh
echo "--^-- X: Reading FASTQ sequences...Done!"

# Compile those pesky individual taxonomic tables into a single
# OTU feature table
echo "--^-- X: Compiling feature table..."
metaxa2_dc -i ./*.level_7.txt -o metaxa-feature-table.tsv
echo "--^-- X: Compiling feature table...Done!"

# Rearrange the feature table to something QIIME likes a little bit better
echo "--^-- X: Rearranging feature table..."
Rscript ./manipulatefeaturetable.R
echo "--^-- X: Rearranging feature table...Done!"


# Pull the column names from the metadata table
echo "--^-- X: Finding metadata columns..."
Rscript ./fetchmetadata.R
echo "--^-- X: Finding metadata columns...Done!"

# Our minimum taxa count is 11123 - this will be needed for rarefaction
MINRAREFACTION=$(<rarefaction.min.txt)
MAXRAREFACTION=$(<rarefaction.max.txt)

# Start up QIIME
# This code creates errors if run through shellcheck because
# the shellcheck program doesn't understand miniconda:
# We'll add a directive to tell it to ignore this error
# shellcheck disable=SC1091
source activate qiime2

# Convert the feature table into BIOM format
echo "--^-- X: Importing data..."
biom convert \
  -i feature-table.tsv \
  -o feature-table.hdf5.biom \
  --table-type="OTU table" \
  --to-hdf5 \
  --process-obs-metadata taxonomy

# Now convert the BIOM table into QIIME format (good grief!)
qiime tools import \
  --input-path feature-table.hdf5.biom \
  --type 'FeatureTable[Frequency]' \
  --input-format 'BIOMV210Format' \
  --output-path feature-table.qza

qiime tools import \
  --input-path feature-table.hdf5.biom \
  --output-path taxonomy.qza \
  --type 'FeatureData[Taxonomy]' \
  --input-format 'BIOMV210Format'
echo "--^-- X: Importing data...Done!"

# We will need to run core-metrics to generate information further down
echo "--^-- X: Running core-metrics..."
rm -r "core-metrics-results"
# This is one of the few QIIME commands that can use multithreading
qiime diversity core-metrics \
  --i-table feature-table.qza \
  --p-sampling-depth "$MINRAREFACTION" \
  --m-metadata-file metadata.tsv \
  --p-n-jobs 4 \
  --output-dir core-metrics-results \
  --verbose
echo "--^-- X: Running core-metrics...Done!"

# Clean out the visualizations, or else QIIME will throw a fit
rm -r "visualizations"
mkdir visualizations

# Create a pretty barplot as a reward for all that effort
echo "--^-- X: Generating barplot..."
qiime taxa barplot \
  --i-table feature-table.qza \
  --i-taxonomy taxonomy.qza \
  --m-metadata-file metadata.tsv \
  --o-visualization visualizations/barplot.qzv
echo "--^-- X: Generating barplot...Done!"

echo "--^-- X: Plotting rarefaction curve..."
# Create a rarefaction curve to make sure the magic of rarefaction is valid
qiime diversity alpha-rarefaction \
  --i-table feature-table.qza \
  --p-max-depth "$MAXRAREFACTION" \
  --m-metadata-file metadata.tsv \
  --o-visualization visualizations/rarefaction-curve.qzv
echo "--^-- X: Plotting rarefaction curve...Done!"

# Run alpha-diversity group significance: this will automatically include all the columns
# Evenness first
echo "--^-- X: Finding alpha-group-significance..."
qiime diversity alpha-group-significance \
  --i-alpha-diversity core-metrics-results/evenness_vector.qza \
  --m-metadata-file metadata.tsv \
  --o-visualization visualizations/evenness-group-significance.qzv \
  --verbose

# Now richness
qiime diversity alpha-group-significance \
  --i-alpha-diversity core-metrics-results/shannon_vector.qza \
  --m-metadata-file metadata.tsv \
  --o-visualization visualizations/shannon-group-significance.qzv \
  --verbose
echo "--^-- X: Finding alpha-group-significance...Done!"

# Now let's find the correlation between alpha-diversity and the numeric traits
echo "--^-- X: Finding alpha-correlations..."
qiime diversity alpha-correlation \
  --i-alpha-diversity core-metrics-results/evenness_vector.qza \
  --m-metadata-file metadata.tsv \
  --p-method pearson \
  --o-visualization visualizations/evenness-correlation.qzv \
  --verbose

qiime diversity alpha-correlation \
  --i-alpha-diversity core-metrics-results/shannon_vector.qza \
  --m-metadata-file metadata.tsv \
  --p-method pearson \
  --o-visualization visualizations/shannon-correlation.qzv \
  --verbose
echo "--^-- X: Finding alpha-correlations...Done!"

# Now for the tricky part: beta-diversity
echo "--^-- X: Checking entries for beta-significance..."
# QIIME only uses one processor for these, so we can parallelize this step
xargs -a catcols.txt -P"$SLURM_NTASKS" -I {} srun -n1 -N1 --exclusive \
  qiime diversity beta-group-significance \
    --i-distance-matrix core-metrics-results/bray_curtis_distance_matrix.qza \
    --m-metadata-file metadata.tsv \
    --m-metadata-column {} \
    --p-pairwise \
    --o-visualization "visualizations/bray-curtis-{}-significance.qzv" \
    --verbose

echo "--^-- X: Checking entries for beta-significance...Done!"

echo "--^-- X: Performing ANCOM..."
# We will try to use ancom on the full dataset, although it might kill us
# Extract pseudocount
qiime composition add-pseudocount \
  --i-table feature-table.qza \
  --o-composition-table composition-table.qza

# Run ancom for all categories in catcols
# Once again, QIIME only uses one processor (even though this
# is a HUGE task), so we should parallelize it for speed
xargs -a catcols.txt -P"$SLURM_NTASKS" -I {} srun -n1 -N1 --exclusive \
  qiime composition ancom \
   --i-table composition-table.qza \
   --m-metadata-file metadata.tsv \
   --m-metadata-column {} \
   --o-visualization "visualizations/ancom-{}.qzv" \
   --verbose
echo "--^-- X: Performing ANCOM...Done!"

# Create category-based predictive models
xargs -a catcols.txt -P"$SLURM_NTASKS" -L1 srun -n1 -N1 --exclusive \
  ./sample-classifier.sh

# Create continuous predictive models
xargs -a numcols.txt -P"$SLURM_NTASKS" -L1 srun -n1 -N1 --exclusive \
  ./sample-regression.sh

echo "--^-- X: All Done!"
