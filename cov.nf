process COVERAGE_FOR_ONE_SAMPLE {

    tag "${tumor_bam.simpleName}"

    publishDir "${params.outdir}/purecn/coverage",
        mode: 'copy'

    container "docker.io/bioconductor/bioconductor_docker:3.18"

    input:
    path tumor_bam
    path tumor_bai
    path fasta

    output:
    path "${tumor_bam.simpleName}.coverage.txt",          emit: coverage
    path "${tumor_bam.simpleName}.coverage_loess.txt",    emit: loess
    path "${tumor_bam.simpleName}.coverage_weights.txt", emit: weights
    path "versions.yml",                                  emit: versions

    script:
    """
    Rscript -e "
        suppressPackageStartupMessages(library(PureCN))

        calculateCoverage(
            bam      = '${tumor_bam}',
            genome   = '${fasta}',
            out.file = '${tumor_bam.simpleName}.coverage.txt'
        )
    "

    cat <<-END_VERSIONS > versions.yml
    PureCN:
      coverage: \$(Rscript -e "packageVersion('PureCN')")
    END_VERSIONS
    """
}
