include { SEQUENZA_GC_WIGGLE } from '../modules/local/sequenza/gc_wiggle/main'

workflow ASCNA {

    take:
    reference_fasta

    main:
    SEQUENZA_GC_WIGGLE(reference_fasta)

    emit:
    gc_wiggle = SEQUENZA_GC_WIGGLE.out
}
