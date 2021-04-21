  <p align="center">
    <img src="https://www.angus.org/Media/pages/ClipArt/graphics/cow_sniff_calf.gif" alt="Logo" width="275">
  </p>

# Cow/calf Rumen Metagenomics Pipeline

An end-to-end script to convert Illumina shotgun sequences and metadata into
full-blown diversity tables and visualizations. Of course, it's focused on the
rumen and dam/calf relationships, but is widely applicable to other systems.

Written entirely during Spring Semester 2019 for work done in [Dr. Hannah
Cunningham-Hollinger's lab][hollinger-lab] at the University of Wyoming,
computed on UW's [ARCC High-performance servers][arcc-servers] and presented as
a [poster] at the Western Section American Association of Animal Science annual
meeting.

## Prerequisites

You will need access to the following commands/programs:

- `metaxa2`, `metaxa2_ttt`, `metaxa2_dc` ([Metaxa2])
- `Rscript` ([R])
- `source activate` ([Miniconda])
- `qiime`, `biom` (Install within [conda environment] named `qiime2`)

If working on a HPC, contact your department to find out how to get access to
these commands.

## Usage

Clone the script files

```bash
git clone https://github.com/MillironX/cowcalf-rumen-metagenomic-pipeline.git
```

Create a directory with all forward- and reverse- read files in it, named as
`<SAMPLEID>_R1_001.fastq.gz` for forward-reads and `<SAMPLEID>_R2_001.fastq.gz`
for reverse-reads. Add a [QIIME2-compatible metadata file][qiime2-metadata]
named `metadata.tsv`, text files containing the minimum and maximum rarefaction
values names `rarefaction.min.txt` and `rarefaction.max.txt` and copy all of the
code files into it. It should look like

```plaintext
.
├── sample1_R1_001.fastq.gz
├── sample1_R2_001.fastq.gz
├── sample2_R1_001.fastq.gz
├── sample2_R2_001.fastq.gz
├── ...
├── sampleN_R1_001.fastq.gz
├── sampleN_R2_001.fastq.gz
├── metadata.tsv
├── rarefaction.min.txt
├── rarefaction.max.txt
├── main.sh
├── fastq-to-taxonomy.sh
├── manipulatefeaturetable.R
├── fetchmetadata.R
├── sample-classifier.sh
└── sample-regression.sh
```

### With Slurm

These scripts are preconfigured for use with [Slurm] and [Lmod]. Everything is
very basic, and should work on any Slurm configuration. Before use, be sure to
replace the provided credentials with your own in `main.sh`,
`fastq-to-taxonomy.sh`, `sample-classifier.sh`, and `sample-regression.sh`, then
run

```bash
sbatch main.sh
```

### Without Slurm

Edit `main.sh` and remove every call to `srun` (including its cli options),
replace every instance of `$SLURM_NTASKS` with the number of parallel threads
you wish to run, and comment out every line that starts `module load`. Then run

```bash
./main.sh
```

## Future Work

This project is finished. It is meant to be a reference and an inspiration, but
nothing more. I do not intend to update the code now (as embarrassing as it
might be).

## Known Issues

- Miniconda now uses the `conda activate` command line instead of `source
  activate`

## License

Distributed under the MIT License. See `LICENSE` for more information.

## Contact

Thomas A. Christensen II - [@MillironX](https://gab.com/MillironX)

Project Link:
[https://github.com/MillironX/cowcalf-rumen-metagenomic-pipline](https://github.com/MillironX/cowcalf-rumen-metagenomic-pipline)

[hollinger-lab]:
https://www.uwyo.edu/anisci/personnel-directory/wyoming-faculty-and-staff/hannah-cunningham-hollinger/index.html
[poster]: https://millironx.com/Academia#metagenomics [arcc-servers]:
https://www.uwyo.edu/arcc/ [slurm]: https://slurm.schedmd.com/overview.html
[qiime2-metadata]: https://docs.qiime2.org/2019.4/tutorials/metadata/ [R]:
https://www.r-project.org/ [metaxa2]: https://microbiology.se/software/metaxa2/
[Miniconda]: https://conda.io/en/master/miniconda.html [conda environment]:
https://docs.qiime2.org/2019.4/install/native/#install-qiime-2-within-a-conda-environment
[Lmod]: https://lmod.readthedocs.io/en/latest/index.html
