#!/bin/bash
# exomedepth_cnv_analysis_v1.0.0

# The following line causes bash to exit at any point if there is any error
# and to output each line as it is executed -- useful for debugging
set -e -x -o pipefail

### Set up parameters
# split project name to get the NGS run number
run=${project_name##*_}

#read the DNA Nexus api key as a variable
API_KEY=$(dx cat project-FQqXfYQ0Z0gqx7XG9Z2b4K43:mokaguys_nexus_auth_key)

# make output dir and folder to hold downloaded files
mkdir -p /home/dnanexus/out/exomedepth_output/exomedepth_output/$bedfile_prefix/ /home/dnanexus/to_test

mark-section "Downloading inputs"
# download all inputs
dx-download-all-inputs --parallel

mark-section "Determining reference genome"
if  [[ $reference_genome_name == *.tar* ]]
	then
		echo "reference is tarball"
		exit 1
elif [[ $reference_genome_name == *.gz ]]
	then 
		gunzip $reference_genome_path
		reference_fasta=$(echo $reference_genome_path | sed 's/\.gz//g')
elif [[ $reference_genome_name == *.fa ]]
	then
		reference_fasta=$reference_genome_path
fi 

mark-section "determine run specific variables"
#Extract samplename to name output files
samplename=$(python -c "basename='$bedfile_prefix'; print basename.split('_R1')[0]")
echo $samplename
echo "read_depth_bed="$bedfile
echo "reference_genome="$reference_fasta
echo "panel="$bamfile_pannumbers
echo "bedfile_prefix="$bedfile_prefix
echo "normals_RData="$normal_RData
output_RData_file="/home/dnanexus/out/exomedepth_output/exomedepth_output/${bedfile_prefix}/${bedfile_prefix}_readCount.RData"
echo "output RData file="$output_RData_file


mark-section "Download all relevant BAMs"
# make and cd to test dir
cd to_test
# $bamfile_pannumbers is a comma seperated list of pannumbers that should be analysed together.
# split this into an array and loop through to download BAM and BAI files
IFS=',' read -ra pannum_array <<<  $bamfile_pannumbers
for panel in ${pannum_array[@]}
do
	# check there is at least one file with that pan number to download otherwise the dx download command will fail
	if (( $(dx ls $project_name:output/*001.ba* --auth $API_KEY | grep $panel -c) > 0 ));
	then
		#download all the BAM and BAI files for this project/pan number
		dx download $project_name:output/*$panel*001.ba* --auth $API_KEY
	fi
done

# Get list of all BAMs in to_test
# NB (include full filepath to ensure the output are absolute paths (needed for docker run))
bam_list=(/home/dnanexus/to_test/*bam)

# count the BAM files. make sure there are at least 3 samples for this pan number, else stop
filecount="${#bam_list[@]}"
if (( $filecount < 3 )); then
	echo "LESS THAN THREE BAM FILES FOUND FOR THIS ANALYSIS" 1>&2
	exit 1
fi

# cd out of to_test
cd /home/dnanexus

mark-section "setting up Exomedepth docker image"
# Location of the ExomeDepth docker file
docker_file=project-ByfFPz00jy1fk6PjpZ95F27J:file-G6kfZYQ0jy1vZ0BF33KZpQjJ
# download the docker file from 001_Tools...
dx download $docker_file --auth "${API_KEY}"
docker load -i '/home/dnanexus/seglh_exomedepth_1220d31.tgz'


mark-section "Calculate read depths using docker image"
# docker run - mount the home directory as a share
# call the readCount.R script
# supply following arguments
#  	- output_RData_file path
#  	- reference_fasta_path 
#  	- bedfile_path 
#	- bam_list 
#	- normals_RData_path
# The log (PanXXXXexomedepth_readCount.csv) written to same location as the $output_RData_file


# Run ReadCount script in docker container
docker run -v /home/dnanexus:/home/dnanexus seglh/exomedepth:1220d31 readCount.R $output_RData_file $reference_fasta $bedfile_path ${bam_list[@]} $normals_RData_path

# Upload results
dx-upload-all-outputs
