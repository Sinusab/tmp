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
  set -euo pipefail

  # clean genes BED: remove header + convert to 0-based start
  awk 'BEGIN{OFS="\\t"}
       NR==1 {next}
       {s=\$2-1; if(s<0)s=0; print \$1,s,\$3,\$4}' ${genes_bed} > genes.clean.bed

  bedtools intersect \
    -a genes.clean.bed \
    -b ${cna_bins_bed} \
    -wa -wb \
    > gene_to_bin.tsv
  """
}
