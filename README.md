# dnanexus_ED_readcount_analysis_v1.3.0
Exome depth is run in two stages. Firstly, read counts are calculated, before CNVs are called using the read counts. Read counts are calculated over the entire genome whereas the CNV calling can be performed using a subpanel.

dnanexus_ED_readcount_analysis_v1.3.0 calculates readcounts for samples using panel of normals and intrabatch samples as reference.

# What does the app do?
This app runs the read count calculation stage.

Using the provided DNANexus project and the list of Pan numbers the app downloads BAMs and BAI.

A Docker image containing Exome depth is downloaded from 001 - The Exomedepth image taken from https://github.com/moka-guys/seglh-cnv/releases/tag/v2.1.0

The `readCount.R` script is then called, producing a readcount file (`PanXXXXexomedepth_readCount.RData`) which can be used as an input for the ED_cnv_calling app https://github.com/moka-guys/dnanexus_ED_cnv_calling

If the panel of normals is not provided then intrabatch normalisation is performed.
# Inputs
* DNAnexus project name where the BAMs and indexes are saved in a folder called '/output'
* Reference_genome (*.fa.gz or *.fa) in build 37
* List of comma seperated pan numbers
* Bedfile covering the capture region
* Optional: panel of normals

# Output
readCount.RData - Read count data and selected references per sample
readCount.csv - Model parameters and QC metrics output (can be used to build a QC classifier, see below)

# Created by
This app was created within the Viapath Genome Informatics section