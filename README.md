# dnanexus_ED_readcount_analysis
This app calculates the readcount for a batch of samples for CNV calling using ExomeDepth.

# What does the app do?

The app downloads the BAMs and its indexes from a specified project in DNAnexus using the given pan numbers. The docker image seglh_exomedepth.tgz uses the BAMs to calculate the readcount file. Further details on the docker image can be found in https://github.com/moka-guys/seglh-cnv/tree/main/exomedepth

The readcount file is then used as an input for the ED_cnv_calling app https://github.com/moka-guys/dnanexus_ED_cnv_calling

# Inputs
DNAnexus project name where the BAMs and indexes are saved in a folder called 'output'
Reference_genome in build 37
List of comma seperated pan numbers
Bedfile covering the capture region
Optional: panel of normals

# Output
readCount.RData - Read count data and selected references per sample
readCount.csv - Model parameters and QC metrics output (can be used to build a QC classifier, see below)

# Created by
This app was created within the Viapath Genome Informatics section