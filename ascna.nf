awk 'BEGIN{OFS="\t"}
     NR==1 {next}                   # header را حذف کن
     {s=$2-1; if(s<0)s=0;           # start را 0-based کن
      print $1,s,$3,$4}' \
  resources/spatial/genes.bed > resources/spatial/genes.clean.bed
