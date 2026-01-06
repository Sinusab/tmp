#!/usr/bin/env Rscript

## =========================
## Spatial RDR from 10X H5
## =========================

args <- commandArgs(trailingOnly = TRUE)

if (length(args) != 4) {
  stop("Usage: rdr_from_h5.R <filtered_feature_bc_matrix.h5> <gene_to_bin.tsv> <out_rdr.tsv> <out_qc.tsv>")
}

h5_file      <- args[1]
gene_to_bin  <- args[2]
out_rdr      <- args[3]
out_qc       <- args[4]

suppressPackageStartupMessages({
  library(Seurat)
  library(Matrix)
  library(data.table)
})

## -------------------------
## 1. Read Visium H5
## -------------------------
cat("Reading H5 file...\n")

mat <- Read10X_h5(h5_file)

# handle multi-assay h5
if (is.list(mat)) {
  if ("Gene Expression" %in% names(mat)) {
    mat <- mat[["Gene Expression"]]
  } else {
    mat <- mat[[1]]
  }
}

# genes x spots
genes <- rownames(mat)
spots <- colnames(mat)

cat("Genes:", length(genes), "\n")
cat("Spots:", length(spots), "\n")

## -------------------------
## 2. Read gene_to_bin
## -------------------------
cat("Reading gene_to_bin...\n")

gtb <- fread(gene_to_bin, header = FALSE)

# Expected columns:
# gene BED (4 cols) + bin BED (at least 3 cols)
# [1] g_chr [2] g_start [3] g_end [4] gene
# [5] b_chr [6] b_start [7] b_end ...

setnames(
  gtb,
  c("g_chr", "g_start", "g_end", "gene",
    "b_chr", "b_start", "b_end",
    paste0("extra_", seq_len(ncol(gtb) - 7)))
)

# keep genes present in expression matrix
gtb <- gtb[gene %in% genes]

if (nrow(gtb) == 0) {
  stop("No overlapping genes between H5 and gene_to_bin")
}

# define bin_id
gtb[, bin_id := paste0(b_chr, ":", b_start, "-", b_end)]

# unique gene → bin mapping
gtb <- unique(gtb[, .(gene, bin_id)])

cat("Bins:", length(unique(gtb$bin_id)), "\n")

## -------------------------
## 3. Aggregate counts per bin
## -------------------------
cat("Aggregating counts per bin...\n")

bins <- split(gtb$gene, gtb$bin_id)
bin_ids <- names(bins)

bin_mat <- matrix(
  0,
  nrow = length(bin_ids),
  ncol = length(spots),
  dimnames = list(bin_ids, spots)
)

for (i in seq_along(bin_ids)) {
  g <- intersect(bins[[i]], genes)
  if (length(g) == 0) next
  bin_mat[i, ] <- Matrix::colSums(mat[g, , drop = FALSE])
}

## -------------------------
## 4. Compute RDR
## -------------------------
cat("Computing RDR...\n")

# median bin count per spot (exclude zeros)
spot_medians <- apply(
  bin_mat,
  2,
  function(x) {
    x <- x[x > 0]
    if (length(x) == 0) return(NA_real_)
    median(x)
  }
)

# avoid division by zero
spot_medians[!is.finite(spot_medians)] <- NA

rdr <- sweep(bin_mat, 2, spot_medians, "/")

## -------------------------
## 5. Write outputs
## -------------------------
cat("Writing outputs...\n")

# RDR: spots × bins
rdr_dt <- as.data.table(t(rdr), keep.rownames = "spot")
fwrite(rdr_dt, out_rdr, sep = "\t")

# QC table
qc_dt <- data.table(
  spot              = spots,
  total_umi         = Matrix::colSums(mat),
  bins_with_counts  = colSums(bin_mat > 0),
  median_bin_umi    = spot_medians
)

fwrite(qc_dt, out_qc, sep = "\t")

cat("Done.\n")
