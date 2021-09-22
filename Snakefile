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

