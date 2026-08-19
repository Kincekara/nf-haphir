include { WTDBG2_ASM as WTDBG2_OPT1 ; WTDBG2_ASM as WTDBG2_OPT2 ; WTDBG2_ASM as WTDBG2_OPT3 } from '../../../modules/local/wtdbg2/'
include { HICANU_ASM as HICANU_OPT1 ; HICANU_ASM as HICANU_OPT2 ; HICANU_ASM as HICANU_OPT3 } from '../../../modules/local/canu/'
include { LJA_ASM as LJA_OPT1 ; LJA_ASM as LJA_OPT2 ; LJA_ASM as LJA_OPT3 } from '../../../modules/local/lja/'

include { COMBINE_ASMS as COMBINE_ATT1 } from '../../../modules/local/autocycler/'
include { COMBINE_ASMS as COMBINE_ATT2 } from '../../../modules/local/autocycler/'
include { COMBINE_ASMS as COMBINE_ATT3 } from '../../../modules/local/autocycler/'

def select_successful_output(output_ch, status_ch) {
    output_ch.join(status_ch).map { joined -> [joined[0], joined[1]] }
}

def select_latest_attempt(output_channels, status_channels) {
    select_successful_output(output_channels[0], status_channels[0])
        .mix(select_successful_output(output_channels[1], status_channels[1]))
        .mix(select_successful_output(output_channels[2], status_channels[2]))
}

workflow CONSENSUS_ASM {
    take:
    ch_assemblies // Format: [ meta, hifiasm_asm, flye_asm, raven_asm ]
    ch_longfq // Format: [ meta, path(long_fq), val(genome_size) ] - Packaged together for simplicity

    main:
    // Resolve user parameter index tracking arrays
    def option_map = [1: ["wtdbg2", "canu", "lja"], 2: ["canu", "lja", "wtdbg2"], 3: ["lja", "wtdbg2", "canu"]]

    def assembly_option = option_map[params.preset.toInteger()]

    // =========================================================================
    // OPTION 1 / ATTEMPT 1: Runs by Default
    // =========================================================================
    ch_wtdbg2_opt1_in = ch_longfq.filter { meta, fq, gsize -> assembly_option[0] == "wtdbg2" }
    WTDBG2_OPT1(ch_wtdbg2_opt1_in)

    ch_hicanu_opt1_in = ch_longfq.filter { meta, fq, gsize -> assembly_option[0] == "canu" }
    HICANU_OPT1(ch_hicanu_opt1_in)

    ch_lja_opt1_in = ch_longfq.filter { meta, fq, gsize -> assembly_option[0] == "lja" }
    LJA_OPT1(ch_lja_opt1_in.map { meta, fq, gsize -> [meta, fq] })    // LJA doesn't use genome size

    // Replicates WDL's 'select_first()' function
    ch_opt1_asm = WTDBG2_OPT1.out.asm.mix(HICANU_OPT1.out.asm, LJA_OPT1.out.asm)
    ch_opt1_ctg_len = WTDBG2_OPT1.out.asm_ctg_len.mix(HICANU_OPT1.out.asm_ctg_len, LJA_OPT1.out.asm_ctg_len)

    // Build tuple: [ meta, hifiasm, flye, raven, opt1_asm ]
    ch_input_att1 = ch_assemblies.join(ch_opt1_asm)

    COMBINE_ATT1(ch_input_att1)

    // Evaluate the content of the RESULT file payload
    ch_att1_evaluated = COMBINE_ATT1.out.result.map { meta, result_file -> [meta, result_file.text.trim()] }
    ch_att1_success = ch_att1_evaluated.filter { meta, res -> res == "SUCCESS" }
    ch_att1_fail = ch_att1_evaluated.filter { meta, res -> res == "FAIL" }

    // =========================================================================
    // OPTION 2 / ATTEMPT 2: Runs ONLY if Attempt 1 Fails
    // =========================================================================
    ch_longfq_att2 = ch_att1_fail.join(ch_longfq).map { meta, res, fq, gsize -> [meta, fq, gsize] }

    // Evaluate if (assembly_option[1] == "...")
    ch_wtdbg2_opt2_in = ch_longfq_att2.filter { meta, fq, gsize -> assembly_option[1] == "wtdbg2" }
    WTDBG2_OPT2(ch_wtdbg2_opt2_in)

    ch_hicanu_opt2_in = ch_longfq_att2.filter { meta, fq, gsize -> assembly_option[1] == "canu" }
    HICANU_OPT2(ch_hicanu_opt2_in)

    ch_lja_opt2_in = ch_longfq_att2.filter { meta, fq, gsize -> assembly_option[1] == "lja" }
    LJA_OPT2(ch_lja_opt2_in.map { meta, fq, gsize -> [meta, fq] })

    // select_first() for Option 2
    ch_opt2_asm = WTDBG2_OPT2.out.asm.mix(HICANU_OPT2.out.asm, LJA_OPT2.out.asm)
    ch_opt2_ctg_len = WTDBG2_OPT2.out.asm_ctg_len.mix(HICANU_OPT2.out.asm_ctg_len, LJA_OPT2.out.asm_ctg_len)

    ch_input_att2 = ch_att1_fail
        .join(ch_assemblies)
        .join(ch_opt2_asm)
        .map { meta, res, hifi, flye, raven, opt2 -> [meta, hifi, flye, raven, opt2] }

    COMBINE_ATT2(ch_input_att2)

    ch_att2_evaluated = COMBINE_ATT2.out.result.map { meta, result_file -> [meta, result_file.text.trim()] }
    ch_att2_success = ch_att2_evaluated.filter { meta, res -> res == "SUCCESS" }
    ch_att2_fail = ch_att2_evaluated.filter { meta, res -> res == "FAIL" }

    // =========================================================================
    // OPTION 3 / ATTEMPT 3: Runs ONLY if BOTH Attempt 1 and Attempt 2 Fail
    // =========================================================================
    ch_longfq_att3 = ch_att2_fail.join(ch_longfq).map { meta, res, fq, gsize -> [meta, fq, gsize] }

    // Evaluate if (assembly_option[2] == "...")
    ch_wtdbg2_opt3_in = ch_longfq_att3.filter { meta, fq, gsize -> assembly_option[2] == "wtdbg2" }
    WTDBG2_OPT3(ch_wtdbg2_opt3_in)

    ch_hicanu_opt3_in = ch_longfq_att3.filter { meta, fq, gsize -> assembly_option[2] == "canu" }
    HICANU_OPT3(ch_hicanu_opt3_in)

    ch_lja_opt3_in = ch_longfq_att3.filter { meta, fq, gsize -> assembly_option[2] == "lja" }
    LJA_OPT3(ch_lja_opt3_in.map { meta, fq, gsize -> [meta, fq] })

    // select_first() for Option 3
    ch_opt3_asm = WTDBG2_OPT3.out.asm.mix(HICANU_OPT3.out.asm, LJA_OPT3.out.asm)
    ch_opt3_ctg_len = WTDBG2_OPT3.out.asm_ctg_len.mix(HICANU_OPT3.out.asm_ctg_len, LJA_OPT3.out.asm_ctg_len)

    ch_input_att3 = ch_att2_fail
        .join(ch_assemblies)
        .join(ch_opt3_asm)
        .map { meta, res, hifi, flye, raven, opt3 -> [meta, hifi, flye, raven, opt3] }

    COMBINE_ATT3(ch_input_att3)

    ch_att3_evaluated = COMBINE_ATT3.out.result.map { meta, result_file -> [meta, result_file.text.trim()] }
    ch_att3_success = ch_att3_evaluated.filter { meta, res -> res == "SUCCESS" }

    // =========================================================================
    // COLLECT TERMINAL OUTPUT STREAMS
    // =========================================================================
    ch_consensus = select_latest_attempt(
        [COMBINE_ATT1.out.asm, COMBINE_ATT2.out.asm, COMBINE_ATT3.out.asm],
        [ch_att1_success, ch_att2_success, ch_att3_success],
    )
    ch_asm_graph = select_latest_attempt(
        [COMBINE_ATT1.out.asm_graph, COMBINE_ATT2.out.asm_graph, COMBINE_ATT3.out.asm_graph],
        [ch_att1_success, ch_att2_success, ch_att3_success],
    )
    ch_asm_ctg_len = select_latest_attempt(
        [COMBINE_ATT1.out.asm_ctg_len, COMBINE_ATT2.out.asm_ctg_len, COMBINE_ATT3.out.asm_ctg_len],
        [ch_att1_success, ch_att2_success, ch_att3_success],
    )

    ch_final_result = ch_att1_success.mix(ch_att2_success, ch_att3_evaluated)

    ch_opt_asm = select_latest_attempt(
        [ch_opt1_asm, ch_opt2_asm, ch_opt3_asm],
        [ch_att1_success, ch_att2_success, ch_att3_success],
    )
    ch_opt_ctg_len = select_latest_attempt(
        [ch_opt1_ctg_len, ch_opt2_ctg_len, ch_opt3_ctg_len],
        [ch_att1_success, ch_att2_success, ch_att3_success],
    )

    emit:
    combined_asm         = ch_consensus
    combined_asm_graph   = ch_asm_graph
    combined_asm_ctg_len = ch_asm_ctg_len
    result               = ch_final_result
    opt_asm              = ch_opt_asm
    opt_ctg_len          = ch_opt_ctg_len
}
