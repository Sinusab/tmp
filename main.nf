include { ASCNA } from './workflows/ascna'

workflow {

    ASCNA(
        reference_fasta: file(params.reference_fasta)
    )
}
