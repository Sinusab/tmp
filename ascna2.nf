process SPACERANGER_BAM {

  tag "${sample_id}"

  publishDir "${params.outdir}/spaceranger/${sample_id}", mode: 'copy', overwrite: true

  input:
    val  sample_id
    path fastq_dir
    path transcriptome
    val  slide
    val  area
    path probe_set optional true

  output:
    path "outs/possorted_genome_bam.bam"
    path "outs/possorted_genome_bam.bam.bai", optional: true
    path "outs/filtered_feature_bc_matrix.h5"
    path "outs/web_summary.html", optional: true
    path "outs/metrics_summary.csv", optional: true

  script:
  def probeArg = (probe_set ? "--probe-set=${probe_set}" : "")

  """
  set -euo pipefail

  spaceranger count \
    --id=${sample_id} \
    --transcriptome=${transcriptome} \
    --fastqs=${fastq_dir} \
    --sample=${sample_id} \
    --slide=${slide} \
    --area=${area} \
    ${probeArg} \
    --create-bam=true \
    --disable-ui
  """
}
