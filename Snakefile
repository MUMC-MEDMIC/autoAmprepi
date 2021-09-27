"""
Giang Le
Automate amprepi

"""


rule all:
    input:
        "AMPREPI.html"


rule analysis:
    input:
        "AMPREPI.Rmd"
    output:
        "AMPREPI.html"
    conda:
        "envAuto.yaml"
    shell:
        """
        Rscript -e "rmarkdown::render('AMPREPI.Rmd')"

        """

onsuccess:
    print("Completed without errors. Congrat")
    shell("mail -s '16S analysis done' giang.le@mumc.nl")

onerror:
    print("An error occurred")
    shell("mail -s 'An error occurred for 16S' giang.le@mumc.nl")
