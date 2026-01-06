#!/usr/bin/env Rscript

## ---------------------------
## Spatial QC for 10x Visium
## ---------------------------

## 1) HPC-safe HDF5 setting
Sys.setenv(HDF5_USE_FILE_LOCKING = "FALSE")

suppressPackageStartupMessages({
  library(Seurat)
  library(rhdf5)
})

## 2) Parse command-line arguments
args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 2) {
  stop("Usage: spatial_qc.R <sample_filtered_feature_bc_matrix.h5> <output_qc.tsv>")
}

h5_file <- args[1]
out_tsv <- args[2]

if (!file.exists(h5_file)) {
  stop(paste("Input H5 file does not exist:", h5_file))
}

## 3) Read 10x Visium counts
counts <- Read10X_h5(h5_file)

## 4) Create minimal Seurat object
seu <- CreateSeuratObject(
  counts = counts,
  assay  = "Spatial",
  project = "Visium_QC"
)

## 5) Basic QC metrics (spot-level)
qc_spots <- data.frame(
  barcode        = colnames(seu),
  nUMI           = seu$nCount_Spatial,
  nFeature       = seu$nFeature_Spatial
)

## 6) Global QC summary
qc_summary <- data.frame(
  n_spots        = ncol(seu),
  mean_UMI       = mean(seu$nCount_Spatial),
  median_UMI     = median(seu$nCount_Spatial),
  mean_features  = mean(seu$nFeature_Spatial),
  median_features= median(seu$nFeature_Spatial)
)

## 7) Write outputs
write.table(
  qc_spots,
  file = sub("\\.tsv$", "_per_spot.tsv", out_tsv),
  sep = "\t",
  quote = FALSE,
  row.names = FALSE
)

write.table(
  qc_summary,
  file = out_tsv,
  sep = "\t",
  quote = FALSE,
  row.names = FALSE
)

message("Spatial QC completed successfully")
