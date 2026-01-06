process GENE_TO_BIN {

  tag "gene_to_bin"

  publishDir params.outdir, mode: 'copy', overwrite: true

  input:
    path genes_bed
    path cna_bins_bed

  output:
    path "gene_to_bin.tsv"

  script:
  """
  bedtools intersect \
    -a ${genes_bed} \
    -b ${cna_bins_bed} \
    -wa -wb \
    > gene_to_bin.tsv
  """
}
