#!/bin/bash
# exomedepth_cnv_analysis_v1.0.0

# Locally stored Docker image to use
DOCKERIMAGEFILE=/home/dnanexus/seglh_exomedepth.tgz

# The following line causes bash to exit at any point if there is any error
# and to output each line as it is executed -- useful for debugging
set -e -x -o pipefail

### Set up parameters
# split project name to get the NGS run number
run=${project_name##*_}

#read the DNA Nexus api key as a variable
API_KEY=$(dx cat project-FQqXfYQ0Z0gqx7XG9Z2b4K43:mokaguys_nexus_auth_key)

#make output dir
mkdir -p /home/dnanexus/out/exomedepth_output/exomedepth_output/$bedfile_prefix/
# make folder to hold downloaded files
mkdir to_test

#
# Download inputs
# download all inputs
dx-download-all-inputs --parallel
#
#dx download "$bedfile"

# make and cd to test dir
cd to_test

mark-section "determine run specific variables"
#Extract samplename to name output files
samplename=$(python -c "basename='$bedfile_prefix'; print basename.split('_R1')[0]")
echo $samplename
echo "read_depth_bed = " $bedfile
echo "reference_genome = " $reference_genome
echo "panel = " $bamfile_pannumbers
echo "bedfile_prefix = " $bedfile_prefix
echo "normals_RData = " $normal_RData
# $bamfile_pannumbers is a comma seperated list of pannumbers that should be analysed together.
# split this into an array and loop through to download BAM and BAI files
IFS=',' read -ra pannum_array <<<  $bamfile_pannumbers
for panel in ${pannum_array[@]}
do
	# check there is at least one bam file with that pan number to download other wise the dx download command will fail
	if (( $(dx ls $project_name:output/*001.ba* --auth $API_KEY | grep $panel -c) > 0 ));
	then
		#download all the BAM and BAI files for this project/pan number
		dx download $project_name:output/*$panel*001.ba* --auth $API_KEY
	fi
done

#Get list of all BAMs 
bam_list=""
bam_list="$(ls /home/dnanexus/to_test/*bam | tr '\n' ' ')"
echo "bam list = " $bam_list


# count the files. make sure there are at least 3 samples for this pan number, else stop
filecount="$(ls *001.ba* | grep . -c)"
if (( $filecount < 6 )); then
	echo "LESS THAN THREE BAM FILES FOUND FOR THIS ANALYSIS" 1>&2
	exit 1
fi

# cd out of to_test
cd ..

mark-section "setting up Exomedepth docker image"
# load/import locally stored docker image
docker load -i ${DOCKERIMAGEFILE}
# get full tag of imported image
DOCKERIMAGENAME=`tar xfO ${DOCKERIMAGEFILE} manifest.json | sed -E 's/.*"RepoTags":\["?([^"]*)"?.*/\1/'`
echo "Using image:"${DOCKERIMAGENAME}

mark-section "Run CNV analysis using docker image"
# docker run - mount the home directory as a share
# Write log direct into output folder
# Get read count for all samples

# Run ReadCount script in docker container
docker run -v /home/dnanexus:/home/dnanexus ${DOCKERIMAGENAME} readCount.R /home/dnanexus/out/exomedepth_output/exomedepth_output/$bedfile_prefix/"$bedfile_prefix"_readCount.RData $reference_genome_path $bedfile_path $bam_list $normals_RData_path

# Run command below to create panel of normals
#docker run -v /home/dnanexus:/home/dnanexus ${DOCKERIMAGENAME} readCount.R /home/dnanexus/out/exomedepth_output/exomedepth_output/$bedfile_prefix/normals.RData $reference_genome_path $bedfile_path $bam_list

# Upload results
dx-upload-all-outputs


