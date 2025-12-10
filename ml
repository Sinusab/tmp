alias nextflow="java -Duser.home=/work/PRTNR/CHUV/DIR/rgottar1/owkin_spatial/ITH-proj/sina_run/scenarioB_pipeline/.nf_home -jar /work/PRTNR/CHUV/DIR/rgottar1/owkin_spatial/ITH-proj/sina_run/scenarioB_pipeline/nf_bin/nextflow-25.04.8-one.jar"

nextflow run main.nf \
  -c configs/CH_L_275a.config \
  --outdir results_CH_L_275a_dummy
