process SPACERANGER_COUNT {

  tag "${sample_id}"

  publishDir params.outdir, mode: 'copy', overwrite: true

  input:
    val sample_id
    path fastq_dir
    path transcriptome
    path probe_set
    val slide
    val area
    path image

  output:
    path "outs/possorted_genome_bam.bam"
    path "outs/filtered_feature_bc_matrix.h5"
    path "outs/spatial"

  script:
  """
  spaceranger count \
    --id=${sample_id} \
    --fastqs=${fastq_dir} \
    --sample=${sample_id} \
    --transcriptome=${transcriptome} \
    --probe-set=${probe_set} \
    --slide=${slide} \
    --area=${area} \
    --image=${image} \
    --create-bam=true \
    --disable-ui
  """
}
