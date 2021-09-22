#!/bin/bash

## Working directory
cd /home/giang.le/income_samples/

## Activate when project file found
if [[ ! -f project.txt ]]; then

	exit
else

	## Remove blank space and blank at the end
	sed 's/ /_/g;s/_$//g' project.txt -i
fi

## Generate runfile from template
cp pre_AMPREPI.Rmd AMPREPI.Rmd

## Exists if no project name
if [ -z $(grep project_name project.txt | awk '{print $2}') ]; then

	echo "Missing project name"
	exit
else

	prject=$(date +"%y%m%d"_$(grep project_name project.txt | awk '{print $2}'))
        echo "Running project $prject"
	mkdir -p $prject
	mv project.txt $prject/
	sed "s/@out_folder/"$prject"/g" AMPREPI.Rmd -i
	runName=$(grep project_name $prject/project.txt | awk '{print $2}')
fi

## Exists if no raw folder
if [ -z $(grep raw_folder $prject/project.txt | awk '{print $2}') ]; then

        echo "Missing raw folder"
        exit
fi

if [ -z $(grep metafile $prject/project.txt | awk '{print $2}') ]; then

        echo "Missing metafile"
        exit
fi

## Check and modify info from project file
for i in project_name raw_folder metafile primer_forward primer_reverse trim_forward trim_reverse min_reads deContam; do

	valFound=$(grep $i $prject/project.txt | awk '{print $2}') 
	if [[ -z "$valFound" ]] ;then

		sed "s/@"$i"//g" AMPREPI.Rmd -i
	else

		sed "s/@"$i"/"$valFound"/g" AMPREPI.Rmd -i
	fi
done 

## Activate snakemake env
source ~/anaconda3/bin/activate SnakeAMPREPI

## Run snakemake
snakemake --use-conda -p --cores 20

mkdir -p completed

## Check project completion
mailTo=$(grep email $prject/project.txt | awk '{print $2}')
if [[ -f $prject/p16sReport/$runName"_finPS.rds" ]]; then

	mail -s "Completed run" $mailTo <<< "Download your report $prject".html" from $prject directory"
	## Remove heavy files
	rm -r $(grep raw_folder $prject/project.txt | awk '{print $2}')
	
	mv $(grep metafile $prject/project.txt | awk '{print $2}') $prject/
	mv AMPREPI.html $prject/$prject".html"

	rm -r $prject/p16sReport/errorRates $prject/p16sReport/filtered $prject/p16sReport/inference
	mv $prject/ completed
else

	mail -s "Failed run" $mailTo <<< "Please contact giang.le@mumc.nl for support "
	mail -s "Failed run" giang.le@mumc.nl <<< "Check error for $prject "
fi





