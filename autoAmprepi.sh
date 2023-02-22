#!/bin/bash

## Working directory
cd /home/giang.le/income_samples/

mkdir -p completed
## Search and remove folders older than 7 days old
find completed/* -type d -ctime +7 -exec rm -rf {} \;

## Clean up input directory
find completed/* -mtime +7 -exec rm {} \;

find input/ -name "uploaddone*" | sort -V > foundupload

## Check running projects
if [[ -s foundupload ]]; then
	
	## Running projects in oder
	while [ $(wc -l foundupload | awk '{print $1}') -ne 0 ]; do

		if [[ -f running ]]; then
			## Condition to check if the program is running real project
			userNamRun=$(sed 's/.*_//g;s/\..*//g' running)
			find . -mindepth 2 -maxdepth 2 -name "project_"$userNamRun".txt" > trueRunning
			if [[ -s trueRunning ]]; then
				echo "Running project $(cat running). Check back later"
				exit
			else
				rm running
			fi
			rm trueRunning
		else

			## Running file
			head -1 foundupload > running
			## Update foundupload
			grep -v "$(cat running)" foundupload > tmp
			mv tmp foundupload

			## Remove window symbols, blank space and blank at the end
			## Check for email
			userNam=$(sed 's/.*_//g;s/\..*//g' running)
			if [ ! -f input/"project_"$userNam".txt" ]; then

				echo "Missing project for upload $userNam"
				rm running $(cat running)
				exit
			else
	
				sed 's/\r//g;s/ /_/g;s/_$//g' input/"project_"$userNam".txt" -i
			fi

			if [ -z $(grep email input/"project_"$userNam".txt" | awk '{print $2}') ]; then
	
				## No analysis without email
				echo "Missing email stop pipeline"
				rm running $(cat running)
				exit
			fi

			## Email to send report to 
			mailTo=$(grep email input/"project_"$userNam".txt" | awk '{print $2}')
			echo "User email is $mailTo"

			for i in project_name raw_folder metafile trim_forward trim_reverse min_reads amplicon_low amplicon_up deContam; do

				if [[ -z $(grep $i input/"project_"$userNam".txt" | awk '{print $2}') ]]; then

					mail -s "Failed AMPREPI: missing $i"  $mailTo <<< "Please check the template or tutorial on how to create the project file. Upload the new project file or contact david.barnett@mumc.nl for support."
					rm running $(cat running)
					exit
				fi
			done

			## Input raw
			## Generate runfile from template
			cp pre_AMPREPI.Rmd AMPREPI.Rmd

			rawDir=$(grep "raw_folder" input/"project_"$userNam".txt" | awk '{print $2}')
			if [ ! -d input/"$rawDir/" ] ; then
	
				mail -s "Failed AMPREPI: No raw folder" $mailTo <<< "Missing raw_folder. Please upload the correct raw folder or contact david.barnett@mumc.nl for support!"
				exit
			else

				if [[ $(find input/"$rawDir/" -name "*fastq*" | wc -l) -eq 0 ]]; then

					mail -s "Failed AMPREPI: No fastq files" $mailTo <<< "No fastq files found in the $rawDir. Please upload the correct raws or contact david.barnett@mumc.nl for support!"
					rm running $(cat running)
					exit
				else

					sed "s/@raw_folder/input\/$rawDir/g" AMPREPI.Rmd -i
				fi
			fi

			## Input meta
			metaFile=$(grep metafile input/"project_"$userNam".txt" | awk '{print $2}')
			if [ ! -f input/"$metaFile" ] ; then
	
				mail -s "Failed AMPREPI: Missing metafile" $mailTo <<< "Unable to find $metaFile make sure the name is correct. Please upload a new correct project file or contact david.barnett@mumc.nl for support!"
				rm running $(cat running)
				exit
			else

			        sed "s/@metafile/input\/$metaFile/g" AMPREPI.Rmd -i
			fi

			## Check primers
			for i in primer_forward primer_reverse; do

				priFound=$(grep $i input/"project_"$userNam".txt" | awk '{print $2}')
				if [[ -z "$priFound" ]] ;then

					sed "s/@"$i"//g" AMPREPI.Rmd -i
				else

					sed "s/@"$i"/"$priFound"/g" AMPREPI.Rmd -i
				fi	

			done

			for i in project_name trim_forward trim_reverse min_reads amplicon_low amplicon_up deContam; do

				valFound=$(grep $i input/"project_"$userNam".txt" | awk '{print $2}') 
				sed "s/@"$i"/"$valFound"/g" AMPREPI.Rmd -i
			done 

			prject=$(date +"%y%m%d"_$(grep project_name input/"project_"$userNam".txt" | awk '{print $2}'))
			echo "Running project $prject"

			mkdir -p $prject
			rm $(cat running)
			mv input/"project_"$userNam".txt" $prject/
			sed "s/@out_folder/$prject/g" AMPREPI.Rmd -i

			## Activate snakemake env
			source ~/.bashrc
                        conda activate SnakeAMPREPI


			mail -s "Starting analysis" $mailTo <<< "Your project $prject is running soon. Once the analysis is done, the report will be sent to you."
			## Run snakemake
			snakemake --use-conda -p --config project=$prject --cores 20

			## Completed analysis
			runName=$(grep project_name $prject/"project_"$userNam".txt" | awk '{print $2}')
			if [[ -f $prject/p16sReport/$runName"_finPS.rds" ]]; then

				## Change the name to the project
				mv $prject".zip" completed/
				if [[ -n $(find completed -name "$prject*" -type f -size +15M) ]]; then

					mail -s "Completed run" $mailTo <<< "Analysis done. However file is too large. Please contact david.barnett@mumc.nl for support"
				else
		
					mail -s "Completed run" -a "completed/${prject}.zip" $mailTo <<< "Please find attached html report. The result will be deleted from ther server in 7 days"
				fi

				## Move raw files to storage
				mv $(grep raw_folder $prject/"project_"$userNam".txt" | awk '{print "input/"$2}') $prject/
				mv $(grep metafile $prject/"project_"$userNam".txt" | awk '{print "input/"$2}') $prject/
				rm -r $prject/p16sReport/filtered $prject/p16sReport/inference

				mv AMPREPI.Rmd $prject/
				mv $prject/ completed
				echo $prject $runName $mailTo >> runlog.txt

			else

				if [[ $mailTo=="david.barnett@mumc.nl" ]]; then

					mail -s "Failed complete run" -A log.txt david.barnett@mumc.nl <<< "Check error for $prject "
				else
					mail -s "Failed complete run" $mailTo <<< "Please contact david.barnett@mumc.nl for support "
					mail -s "Failed complete run" -A log.txt david.barnett@mumc.nl <<< "Check error for $prject "
				fi

				mv log.txt AMPREPI.Rmd $prject/
			fi
			rm running
		fi
	done
else

	echo "No uploaded files for analysis"
	exit
fi







