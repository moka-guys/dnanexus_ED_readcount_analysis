# dnanexus_ED_readcount_analysis_v1.3.1
Exome depth is run in two stages. Firstly, read counts are calculated, before CNVs are called using the read counts. Read counts are calculated over the entire genome whereas the CNV calling can be performed using a subpanel.

dnanexus_ED_readcount_analysis_v1.3.1 calculates readcounts for samples using panel of normals and intrabatch samples as reference.

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
* Optional: list of excluded samples (list of comma seperated sample name(s). e.g. NGS629_17_336408,NGS629_04_336112)

# Output
readCount.RData - Read count data and selected references per sample
readCount.csv - Model parameters and QC metrics output (can be used to build a QC classifier, see below)

# CLI command line to run the app
Example command line to run the app below:
```
dx run applet-GpyBKj00ybJ4pzvJJgZ3pKb4 \
-iproject_name=003_240814_update_readcount_app_to_exclude_samples \
-ibamfile_pannumbers=Pan4149,Pan4817,Pan4816 \
-ireference_genome=project-ByfFPz00jy1fk6PjpZ95F27J:file-B6ZY7VG2J35Vfvpkj8y0KZ01 \
-ibedfile=project-ByfFPz00jy1fk6PjpZ95F27J:file-GZZXB6j0jy1j9vgYk767BfFQ \
-inormals_RData=project-ByfFPz00jy1fk6PjpZ95F27J:file-Gbkgyq00ZpxpFKx03zVPJ9GX \
-iexcluded_samples=NGS629_17_336408,NGS629_04_336112

```

# Created by
This app was created within the Viapath Genome Informatics section