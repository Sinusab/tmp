/*
 * main.nf
 * -----------------------------------------
 * Atomic pipeline (DSL2) entrypoint
 * This workflow takes a tumor BAM, reference genome FASTA,
 * and SNP VCF, then runs allele-specific CNA calling via
 * the CALL_ASCN module.
 */

nextflow.enable.dsl = 2   // Enable Nextflow DSL2 syntax (required for include/workflow)

/*
 * Import the ASCNA module.
 * The file ./modules/wes_ascna.nf (or directory ./modules/wes_ascna/)
 * must export a workflow/process named CALL_ASCN.
 */
include { CALL_ASCN } from './modules/wes_ascna'

/*
 * ---------------------------
 * Pipeline parameters
 * ---------------------------
 * These can be set via CLI:
 *   --tumor_bam    path/to/sample.bam
 *   --genome_fasta path/to/genome.fa
 *   --snp_vcf      path/to/snps.vcf.gz
 * Optional:
 *   --outdir       results/
 */
params.tumor_bam    = null        // Tumor BAM to analyze (required)
params.genome_fasta = null        // Reference genome FASTA (required)
params.snp_vcf      = null        // Germline/common SNP set VCF.gz (required)
params.outdir       = 'results'   // Output directory (optional default)

workflow {

    /*
     * Validate required parameters early.
     * If any are missing, stop execution with a helpful message.
     */
    if( !params.tumor_bam || !params.genome_fasta || !params.snp_vcf ) {
        error """
        Missing required params.

        Please run like:

          nextflow run main.nf \\
            --tumor_bam    path/to/tumor.bam \\
            --genome_fasta path/to/genome.fa \\
            --snp_vcf      path/to/snps.vcf.gz

        """
    }

    /*
     * Create input channels from provided file paths.
     * Channel.fromPath() converts the given path (or glob) into a file channel.
     * .set { name } stores the channel in a variable for later use.
     */
    Channel.fromPath(params.tumor_bam)    .set { ch_tumor_bam }
    Channel.fromPath(params.genome_fasta) .set { ch_genome_fasta }
    Channel.fromPath(params.snp_vcf)      .set { ch_snp_vcf }

    /*
     * Run allele-specific CNA calling.
     * The CALL_ASCN module is responsible for downstream processes and outputs.
     */
    CALL_ASCN(
        ch_tumor_bam,
        ch_genome_fasta,
        ch_snp_vcf
    )
}
