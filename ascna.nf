#!/usr/bin/env Rscript
args <- commandArgs(trailingOnly=TRUE)
h5 <- args[1]
gene_to_bin <- args[2]
qc_per_spot <- args[3]
out_rdr <- args[4]
out_qc <- args[5]

suppressPackageStartupMessages({
  library(Matrix)
  library(data.table)
  library(Seurat)
})

# read 10x h5
m <- Read10X_h5(h5)
if (is.list(m)) {
  if ("Gene Expression" %in% names(m)) m <- m[["Gene Expression"]] else m <- m[[1]]
}
# m: genes x spots
genes <- rownames(m)
spots <- colnames(m)

gtb <- fread(gene_to_bin, header=FALSE)
# genes.bed(4 cols) + bins(>=3 cols) => columns:
# 1 chr_g,2 start_g,3 end_g,4 gene, 5 chr_b,6 start_b,7 end_b, ...
setnames(gtb, c("g_chr","g_start","g_end","gene","b_chr","b_start","b_end", paste0("b_extra", seq_len(ncol(gtb)-7))))
gtb <- gtb[gene %in% genes]

# define bin_id as chr:start-end
gtb[, bin_id := paste0(b_chr, ":", b_start, "-", b_end)]

# optional spot filtering by qc_per_spot
keep_spots <- spots
if (!is.na(qc_per_spot) && qc_per_spot != "NONE" && file.exists(qc_per_spot)) {
  qc <- fread(qc_per_spot)
  # تلاش برای یافتن ستون spot/barcode
  spot_col <- intersect(names(qc), c("barcode","spot","spot_id","barcodes"))
  if (length(spot_col) > 0) {
    spot_col <- spot_col[1]
    # اگر ستون pass/fail داری استفاده می‌کنیم
    pass_col <- intersect(names(qc), c("pass","PASS","qc_pass","keep"))
    if (length(pass_col) > 0) {
      pass_col <- pass_col[1]
      qc_pass <- qc[get(pass_col) %in% c(TRUE,1,"1","TRUE","pass","PASS","keep","KEEP")]
      keep_spots <- intersect(spots, qc_pass[[spot_col]])
    } else {
      keep_spots <- intersect(spots, qc[[spot_col]])
    }
  }
}

m <- m[, keep_spots, drop=FALSE]

# aggregate counts per bin
# build gene -> bin_id mapping (اگر ژن چندبار آمده، unique)
gtb_unique <- unique(gtb[, .(gene, bin_id)])

# split genes by bin
bins <- split(gtb_unique$gene, gtb_unique$bin_id)

# compute bin counts per spot
bin_ids <- names(bins)
bin_mat <- matrix(0, nrow=length(bin_ids), ncol=ncol(m))
rownames(bin_mat) <- bin_ids
colnames(bin_mat) <- colnames(m)

for (i in seq_along(bin_ids)) {
  g <- bins[[i]]
  g <- intersect(g, rownames(m))
  if (length(g) == 0) next
  bin_mat[i, ] <- Matrix::colSums(m[g, , drop=FALSE])
}

# normalize to RDR per spot: divide by median across bins (avoid zeros)
med <- apply(bin_mat, 2, function(x) median(x[x>0], na.rm=TRUE))
med[!is.finite(med) | med==0] <- NA
rdr <- sweep(bin_mat, 2, med, "/")

# write outputs
rdr_dt <- data.table(bin_id=rownames(rdr))
rdr_dt <- cbind(rdr_dt, as.data.table(t(rdr), keep.rownames="spot"))
# better: spots as rows
rdr_spot <- as.data.table(t(rdr), keep.rownames="spot")
setnames(rdr_spot, "rn", "spot")
fwrite(rdr_spot, out_rdr, sep="\t")

qc_dt <- data.table(
  spot = colnames(m),
  total_umi = Matrix::colSums(m),
  bins_with_counts = colSums(bin_mat > 0, na.rm=TRUE),
  median_bin_umi = med
)
fwrite(qc_dt, out_qc, sep="\t")
