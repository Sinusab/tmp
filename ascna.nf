qc <- data.frame(
  n_spots    = n_spots,
  n_genes    = n_genes,
  mean_umi   = mean(umi_per_spot),
  median_umi = median(umi_per_spot),
  min_umi    = min(umi_per_spot),
  max_umi    = max(umi_per_spot),
  frac_low_umi = mean(umi_per_spot < 100),
  sparsity   = 1 - (length(data) / (n_genes * n_spots))
)
