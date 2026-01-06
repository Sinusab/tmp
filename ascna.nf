process RDR_FROM_H5 {

  tag "rdr_from_h5"

  publishDir params.outdir, mode: 'copy', overwrite: true

  input:
    path h5
    path gene_to_bin
    path qc_per_spot optional true

  output:
    path "rdr_per_spot_per_bin.tsv"
    path "rdr_qc.tsv"

  script:
  """
  Rscript ${moduleDir}/rdr_from_h5.R \
    ${h5} \
    ${gene_to_bin} \
    ${qc_per_spot:-NONE} \
    rdr_per_spot_per_bin.tsv \
    rdr_qc.tsv
  """
}
