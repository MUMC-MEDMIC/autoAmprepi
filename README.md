# autoAmprepi

The script is the automation part to run 16S analysis from window machines in the office.
Winscp is required for the transfer of files/
Please contact MIT if you dont have access to Winscp.

## How to run

Three things are required: fastq folder, metafile and setting file.

For information on how to format the metafile check [(here)](https://github.com/MUMC-MEDMIC/AMPREPI/blob/master/tutorial/prepare_run.md)
 
The setting file is tab seperated.
The left column is fixed.
Fill in the information on the right side.

|                |                  |
|----------------|------------------|
| project_name   | name_of_project  |
| raw_folder     | fastq_folder     |
| metafile       | metafile.csv     |
| primer_forward | (optinal)        |
| primer_reverse | (optonal)        |
| trim_forward   | 240              |
| trim_reverse   | 160              |
| min_reads      | 1000             |
| deContam       | either           |
| email          | giang.le@mumc.nl |


Please provide all the requested information.
To check if primers are still present in the raw file, provide primers sequences.

Crontab will check if new files are available.
Upond detecting these files, AMPREPI will be activated.
The status of the analysis is sent to the provided email address.

