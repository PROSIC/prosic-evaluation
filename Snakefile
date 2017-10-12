import pandas as pd

from snakemake.remote import FTP

ftp = FTP.RemoteProvider()


gdc_manifest = pd.read_table(config["gdc-manifest"])
units = pd.DataFrame({
    "sample": gdc_manifest.filename.str.slice(5, 33),
    "path": gdc_manifest.filename})
units.index = gdc_manifest.id


rule all:
    input:
        expand("mapped/{unit}.bam", units=units.index)


rule get_bam:
    input:
        config["gdc-manifest"]
    output:
        temp(gdc_manifest.filename)
    shell:
        "gdc-client {input}"


rule bam2fq:
    input:
        lambda wildcards: units.loc[wildcards.unit]
    output:
        "reads/{unit}.1.fastq",
        "reads/{unit}.2.fastq"
    shell:
        "samtools bam2fq {input} {output}"


rule bowtie2_index:
    input:
        ftp.remote(config["ref"]["index"])
    output:
        "index"
    shell:
        "unzip -d {output} {input}"


rule qtip:
    input:
        index="index"
        m1="reads/{unit}.1.fastq",
        m2="reads/{unit}.2.fastq"
    output:
        "mapped/{unit}.bam"
    conda:
        "envs/qtip.yaml"
    shell:
        "qtip --m1 {input.m1} --m2 {input.m2} --index {input.index} | "
        "samtools view -Sb - > {output}"


# TODO calling and concordance analysis
