#!/bin/bash
# exomedepth_cnv_analysis_v1.3.0

# The following line causes bash to exit at any point if there is any error
# and to output each line as it is executed -- useful for debugging
set -e -x -o pipefail

### Set up parameters
# split project name to get the NGS run number
run=${project_name##*_}

#read the DNA Nexus api key as a variable
API_KEY_wquotes=$(echo $DX_SECURITY_CONTEXT |  jq '.auth_token')
API_KEY=$(echo "$API_KEY_wquotes" | sed 's/"//g')
echo "$API_KEY"

output_RData_dir="/home/dnanexus/out/RData/exomedepth_output/${bedfile_prefix}"
output_RData_file="${output_RData_dir}/${bedfile_prefix}_readCount.RData"
output_CSV_dir="/home/dnanexus/out/csv/exomedepth_output/${bedfile_prefix}/"

# make output dir and folder to hold downloaded files
mkdir -p /home/dnanexus/to_test $output_CSV_dir $output_RData_dir

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
echo "read_depth_bed="$bedfile
echo "reference_genome="$reference_fasta
echo "panel="$bamfile_pannumbers
echo "bedfile_prefix="$bedfile_prefix
echo "normals_RData="$normals_RData


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
		dx download -f $project_name:output/*$panel*001.ba* --auth $API_KEY
	fi
done

# Get list of all BAMs in to_test
# NB (include full filepath to ensure the output are absolute paths (needed for docker run))
bam_list=(/home/dnanexus/to_test/*bam)

# remove the bam(s) from the list if excluded_samples is provided 
if [ "$excluded_samples" ]
then
    IFS=',' read -ra excluded_samples_array <<<  $excluded_samples
    for del in "${excluded_samples_array[@]}"; do
        for i in "${!bam_list[@]}"; do
            if [[ ${bam_list[i]} = *$del* ]]; then
                unset 'bam_list[i]'
            fi
        done
    done
fi

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
docker_file_id=project-ByfFPz00jy1fk6PjpZ95F27J:file-Gbjy9yj0JQXkKB8bfFz856V6
# download the docker file from 001_Tools...
dx download $docker_file_id --auth "${API_KEY}"
docker_file=$(dx describe ${docker_file_id} --name)
DOCKERIMAGENAME=`tar xfO ${docker_file} manifest.json | sed -E 's/.*"RepoTags":\["?([^"]*)"?.*/\1/'`
docker load < /home/dnanexus/"${docker_file}"
#docker pull seglh/exomedepth:1111b6c
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
docker run -v /home/dnanexus:/home/dnanexus ${DOCKERIMAGENAME} readCount.R $output_RData_file $reference_fasta $bedfile_path ${bam_list[@]} $normals_RData_path

# Move outputs into output folders to delocalise into dnanexus project
mv $output_RData_dir/*.csv $output_CSV_dir

# Upload results
dx-upload-all-outputs