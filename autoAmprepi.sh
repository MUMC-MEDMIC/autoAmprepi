#!/bin/bash

## Working directory
cd /home/giang.le/income_samples/

mkdir -p completed
## Search and remove folders older than 7 days old
find completed/* -type d -ctime +7 -exec rm -rf {} \;

## Clean up input directory
find completed/* -mtime +7 -exec rm {} \;

# Generate runfile from template
cp pre_AMPREPI.Rmd AMPREPI.Rmd

## Check upload progress
if [[ ! -f input/uploaddone.txt ]]; then

	echo "No uploaded files for analysis"
        exit
fi

## Check project file
if [[ ! -f input/project.txt ]]; then

	echo "No project file to run"
	exit
else

	## Remove window symbols, blank space and blank at the end
	sed 's/\r//g;s/ /_/g;s/_$//g' input/project.txt -i
fi


## Check for email
if [ -z $(grep email input/project.txt | awk '{print $2}') ]; then
	
	## No analysis without email
	exit
fi

## Email to send report to 
mailTo=$(grep email input/project.txt | awk '{print $2}')

## Exists if no project name
if [ ! -z $(grep project_name input/project.txt | awk '{print $2}') ]; then

	prject=$(date +"%y%m%d"_$(grep project_name input/project.txt | awk '{print $2}'))
        echo "Running project $prject"
	mkdir -p $prject
	rm input/uploaddone.txt
	mv input/project.txt $prject/
	sed "s/@out_folder/$prject/g" AMPREPI.Rmd -i
else
	
	mail -s "Failed AMPREPI: Missing project name" $mailTo <<< "Missing project_name. Please upload a new correct project file or contact giang.le@mumc.nl for support!"
	exit
fi


## Input raw
rawDir=$(grep raw_folder $prject/project.txt | awk '{print $2}')
if [ ! -d input/"$rawDir" ] ; then
	
	mail -s "Failed AMPREPI: Wrong raw folder" $mailTo <<< "Missing raw_folder. Please upload a new correct project file or contact giang.le@mumc.nl for support!"
	exit
else

	sed "s/@raw_folder/input\/$rawDir/g" AMPREPI.Rmd -i
fi

## Input meta
metaFile=$(grep metafile $prject/project.txt | awk '{print $2}')
if [ ! -f input/"$metaFile" ] ; then
	
	mail -s "Failed AMPREPI: Missing metafile" $mailTo <<< "Incorrect metafile. Please upload a new correct project file or contact giang.le@mumc.nl for support!"
	exit
else

        sed "s/@metafile/input\/$metaFile/g" AMPREPI.Rmd -i
fi



## Check primers
for i in primer_forward primer_reverse; do

	priFound=$(grep $i $prject/project.txt | awk '{print $2}')
	if [[ -z "$priFound" ]] ;then

		sed "s/@"$i"//g" AMPREPI.Rmd -i
	else

		sed "s/@"$i"/"$valFound"/g" AMPREPI.Rmd -i
	fi	

done

for i in project_name trim_forward trim_reverse min_reads deContam; do

	valFound=$(grep $i $prject/project.txt | awk '{print $2}') 
	if [[ -z "$valFound" ]] ;then

		mail -s "Failed AMPREPI: Missing $i" $mailTo <<< "Incorrect or missing $i. Please upload a new correct project file or contact giang.le@mumc.nl for support!"
		exit
	else

		sed "s/@"$i"/"$valFound"/g" AMPREPI.Rmd -i
	fi
done 


## Activate snakemake env
source ~/anaconda3/bin/activate SnakeAMPREPI

## Run snakemake
snakemake --use-conda -p --cores 20

## Completed analysis
runName=$(grep project_name $prject/project.txt | awk '{print $2}')
if [[ -f $prject/p16sReport/$runName"_finPS.rds" ]]; then

	## Change the name to the project
	mv AMPREPI.zip completed/$prject".zip"
	rm AMPREPI.*
	if [[ -n $(find completed -name "$prject*" -type f -size +15M) ]]; then

		mail -s "Completed run" $mailTo <<< "Analysis done. However file is too large. Please contact giang.le@mumc.nl for support"
	else
		
		mail -s "Completed run" -a "completed/${prject}.zip" $mailTo <<< "Please find attached html report. The result will be deleted from ther server in 7 days"
	fi
	## Move raw files to storage
	mv $(grep raw_folder $prject/project.txt | awk '{print "input/"$2}') $(grep metafile $prject/project.txt | awk '{print "input/"$2}') $prject/

	rm -r $prject/p16sReport/errorRates $prject/p16sReport/filtered $prject/p16sReport/inference
	mv $prject/ completed
	echo $runName $mailTo >> runlog.txt

else

	if [[ $mailTo=="giang.le@mumc.nl" ]]; then

		mail -s "Failed complete run" giang.le@mumc.nl <<< "Check error for $prject "
	else
		mail -s "Failed complete run" $mailTo <<< "Please contact giang.le@mumc.nl for support "
		mail -s "Failed complete run" giang.le@mumc.nl <<< "Check error for $prject "
	fi
fi


