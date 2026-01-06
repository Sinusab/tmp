#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 2) {
  stop("Usage: Rscript spatial_qc.R <input_h5> <output_tsv>")
}

h5_file  <- args[1]
out_file <- args[2]

suppressPackageStartupMessages({
  library(rhdf5)
})

h5 <- H5Fopen(h5_file)

data   <- h5read(h5, "/matrix/data")
indptr <- h5read(h5, "/matrix/indptr")
shape  <- h5read(h5, "/matrix/shape")

H5Fclose(h5)

n_genes <- shape[1]
n_spots <- shape[2]

umi_per_spot <- sapply(
  1:(length(indptr) - 1),
  function(i) {
    sum(data[(indptr[i] + 1):indptr[i + 1]])
  }
)

qc <- data.frame(
  n_spots      = n_spots,
  n_genes      = n_genes,
  mean_umi     = mean(umi_per_spot),
  median_umi   = median(umi_per_spot),
  min_umi      = min(umi_per_spot),
  max_umi      = max(umi_per_spot),
  frac_low_umi = mean(umi_per_spot < 100),
  sparsity     = 1 - (length(data) / (n_genes * n_spots))
)

write.table(
  qc,
  file = out_file,
  sep = "\t",
  row.names = FALSE,
  quote = FALSE
)
