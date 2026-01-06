process SPACERANGER_BAM_SIMPLE {

  tag "${sample_id}"

  publishDir "${params.outdir}/spaceranger/${sample_id}", mode: 'copy', overwrite: true

  input:
    val  sample_id
    path fastq_dir
    path transcriptome

  output:
    path "outs/possorted_genome_bam.bam"
    path "outs/possorted_genome_bam.bam.bai"
    path "outs/filtered_feature_bc_matrix.h5"

  script:
  """
  set -euo pipefail

  spaceranger count \
    --id=${sample_id} \
    --transcriptome=${transcriptome} \
    --fastqs=${fastq_dir} \
    --sample=${sample_id} \
    --create-bam=true

  samtools index outs/possorted_genome_bam.bam
  """
}
