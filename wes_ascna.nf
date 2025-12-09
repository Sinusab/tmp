process CALL_ASCN {

    // Short label shown in Nextflow logs/UI (e.g. CALL_ASCN (sample123))
    // simpleName = filename without path and extension
    tag "${tumor_bam.simpleName}"

    // Where to publish final output files for this process
    // params.outdir is given at runtime (e.g. --outdir results_patient1)
    publishDir "${params.outdir}/ascna", mode: 'copy'

    /*
     * INPUTS
     * These come from the channels passed in main.nf:
     *
     * CALL_ASCN(
     *   ch_tumor_bam,
     *   ch_genome_fasta,
     *   ch_snp_vcf
     * )
     *
     * Each 'path' directive consumes one item from the corresponding channel
     * and exposes it inside the process as a file path variable.
     */
    input:
    path tumor_bam       // tumor BAM file
    path genome_fasta    // reference genome FASTA
    path snp_vcf         // SNP VCF (germline / panel of SNPs)

    /*
     * OUTPUTS
     *
     * After the script finishes, Nextflow expects these two files to exist
     * in the process working directory. They are then:
     *   - emitted on named output channels (segments, meta)
     *   - copied to publishDir (results/.../ascna)
     */
    output:
    path "ascna_segments.tsv", emit: segments  // ASCNA segments per bin
    path "ascna_meta.tsv"    , emit: meta      // purity, ploidy, etc.

    /*
     * SCRIPT
     *
     * This block is executed as a bash script on the compute node.
     * Variables:
     *   - ${params.run_purecn} : path to the R script (set in nextflow.config)
     *   - $tumor_bam, $genome_fasta, $snp_vcf : input files defined above
     *
     * The R script is responsible for creating:
     *   - ascna_segments.tsv
     *   - ascna_meta.tsv
     */
    script:
    """
    Rscript ${params.run_purecn} \
        --tumor $tumor_bam \
        --fasta $genome_fasta \
        --snps  $snp_vcf \
        --out_prefix ascna

    # We assume the R script writes:
    #   ascna_segments.tsv
    #   ascna_meta.tsv
    """
}
