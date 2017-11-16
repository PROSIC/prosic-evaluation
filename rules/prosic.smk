rule prosic_call:
    input:
        calls="{caller}/{run}.all.bcf",
        ref=get_ref,
        bams=get_bams,
        bais=get_bais
    output:
        temp("prosic-{caller}/{run}.{chrom}.bcf")
    params:
        isize=lambda wc: config["datasets"][config["runs"][wc.run]["dataset"]]["isize"]
    log:
        "logs/prosic-{caller}/{run}.log"
    benchmark:
        "benchmarks/prosic-{caller}/{run}.tsv"
    # conda:
    #     "../envs/prosic.yaml"
    shell:
        "bcftools view {input.calls} {wildcards.chrom} | "
        "prosic call-tumor-normal {input.bams} {input.ref} "
        "--isize-mean {params.isize[mean]} --isize-sd {params.isize[sd]} "
        "{config[caller][prosic][params]} "
        "> {output} 2> {log}"


rule prosic_merge:
    input:
        expand("prosic-{{caller}}/{{run}}.{chrom}.bcf", chrom=CHROMOSOMES)
    output:
        "prosic-{caller}/{run}.all.bcf"
    wrapper:
        "0.19.1/bio/bcftools/concat"


rule prosic_control_fdr:
    input:
        "prosic-{caller}/{run}.all.bcf"
    output:
        "prosic-{caller}/{run}.gamma.{type}.tsv"
    # conda:
    #     "../envs/prosic.yaml"
    shell:
        "prosic control-fdr --event SOMATIC --var {wildcards.type} "
        "--method ev {input} > {output}"
