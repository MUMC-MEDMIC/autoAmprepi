"""
Giang Le
Automate amprepi

"""


rule all:
    input:
        expand("{aproject}.zip", aproject=config['project']) 


rule analysis:
    input:
        "AMPREPI.Rmd"
    output:
        temp("{aproject}.html")
    conda:
        "envAuto.yaml"
    shell:
        """
        Rscript -e "rmarkdown::render('AMPREPI.Rmd', output_file='{output}')" &> log.txt
        """

rule zipFile:
    input:
        "{aproject}.html"
    output:
        "{aproject}.zip"
    conda:
        "envAuto.yaml"
    shell:
        """
        zip {output} {input}
        """

onerror:
    print("An error occurred")
#    shell("mail -s 'An error occurred for 16S' giang.le@mumc.nl < {log} ")
