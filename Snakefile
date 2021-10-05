"""
Giang Le
Automate amprepi

"""


rule all:
    input:
        "AMPREPI.zip"


rule analysis:
    input:
        "AMPREPI.Rmd"
    output:
        "AMPREPI.html"
    conda:
        "envAuto.yaml"
    shell:
        """
        Rscript -e "rmarkdown::render('AMPREPI.Rmd')" &> log.txt
        """

rule zipFile:
    input:
        "AMPREPI.html"
    output:
        "AMPREPI.zip"
    conda:
        "envAuto.yaml"
    shell:
        """
        zip AMPREPI.zip AMPREPI.html
        """

onerror:
    print("An error occurred")
    shell("mail -s 'An error occurred for 16S' giang.le@mumc.nl")
