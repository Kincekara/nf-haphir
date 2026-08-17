include { WTDBG2_ASM   } from '../../../modules/local/wtdbg2/'
include { HICANU_ASM   } from '../../../modules/local/canu/'
include { LJA_ASM      } from '../../../modules/local/lja/'
include { COMBINE_ASMS } from '../../../modules/local/autocycler/'


workflow CONSENSUS_ASM {
    take:
    ch_assemblies
    ch_longfq
    attempt

    main:
    // define presets
    def assembly_option
    if (params.assembly_preset == 1) {
        assembly_option = (["wtdbg2", "canu", "lja"])
    }
    else if (params.assembly_preset == 2) {
        assembly_option = (["canu", "lja", "wtdbg2"])
    }
    else if (params.assembly_preset == 3) {
        assembly_option = (["lja", "wtdbg2", "canu"])
    }

    if (assembly_option[attempt] == "wtdbg2") {
        WTDBG2_ASM(ch_longfq)
        asm = WTDBG2_ASM.out.asm
        ctg_len = WTDBG2_ASM.out.asm_ctg_len
    }
    else if (assembly_option[attempt] == "canu") {
        HICANU_ASM(ch_longfq)
        asm = HICANU_ASM.out.asm
        ctg_len = HICANU_ASM.out.asm_ctg_len
    }
    else if (assembly_option[attempt] == "lja") {
        LJA_ASM(ch_longfq)
        asm = LJA_ASM.out.asm
        ctg_len = LJA_ASM.out.asm_ctg_len
    }

    COMBINE_ASMS(ch_assemblies.join(asm))

    emit:
    combined_asm         = COMBINE_ASMS.out.asm
    combined_asm_graph   = COMBINE_ASMS.out.asm_graph
    combined_asm_ctg_len = COMBINE_ASMS.out.asm_ctg_len
    result               = COMBINE_ASMS.out.result
    opt_asm              = asm
    opt_ctg_len          = ctg_len
}
