process COMBINE_ASMS {

    tag "$meta.id"
    label 'process_high'
    container 'staphb/autocycler:0.6.2'

    input:
    tuple val(meta), path(hifiasm_asm), path(flye_asm), path(raven_asm), path(opt_asm)

    output:
    tuple val(meta), path("*.autocycler.fasta"), emit: asm
    tuple val(meta), path("*.autocycler.gfa"), emit: asm_graph
    tuple val(meta), path("*.autocycler.ctg_len.txt"), emit: asm_ctg_len
    tuple val("${task.process}"), val('autocycler'), eval("autocycler --version | cut -d ' ' -f2"), emit: versions_autocycler, topic: versions
    tuple val(meta), path("RESULT"), emit: result

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    # create helper functions
    run_autocycler() {
        local input_dir="\$1" output_dir="\$2" log_file="\$3"
        autocycler compress -i "\$input_dir" -a "\$output_dir"
        autocycler cluster -a "\$output_dir"
        for c in "\$output_dir"/clustering/qc_pass/cluster_*; do
            [ -d "\$c" ] || continue
            autocycler trim -c "\$c"
            autocycler resolve -c "\$c"
        done
        autocycler combine -a "\$output_dir" -i "\$output_dir"/clustering/qc_pass/cluster_*/5_final.gfa 2> "\$log_file"
    }

    finalize_output() {
        local src_prefix="\$1" dst_prefix="\$2"
        if [ -f "\$src_prefix".fasta ]; then
            mv "\$src_prefix".fasta "\$dst_prefix".fasta
        fi
        if [ -f "\$src_prefix".gfa ]; then
            mv "\$src_prefix".gfa "\$dst_prefix".gfa
        fi
    }

    clean_short_contigs() {
        local input="\$1" output="\$2"
        awk 'BEGIN {RS=">"; FS="\\n"} NR>1 {seq=""; for (i=2; i<=NF; i++) seq=seq\$i; if (length(seq) >= 2000) printf ">%s", \$0}' "\$input" > "\$output"
    }

    # collect assemblies
    mkdir assemblies
    cp ${hifiasm_asm} ${flye_asm} ${raven_asm} ${opt_asm} assemblies/

    # give extra consensus weight to contigs from Hifiasm and Flye 
    sed -i 's/^>.*\$/& Autocycler_consensus_weight=2/' assemblies/*hifiasm.fasta
    sed -i 's/^>.*\$/& Autocycler_consensus_weight=2/' assemblies/*flye.fasta
    
    # run autocycler
    run_autocycler "assemblies" "autocycler_out" "combine.log"
    
    # check if consensus assembly is fully resolved
    if grep -q "Consensus assembly is fully resolved" combine.log; then
        echo "Consensus assembly is fully resolved"
        finalize_output "autocycler_out/consensus_assembly" "${prefix}.autocycler"
        echo "SUCCESS" > RESULT
    elif grep -q "One or more clusters failed to fully resolve" combine.log; then
        echo "Checking chromosome..."
        # check if chromosome is fully resolved
        if head -n 1 autocycler_out/consensus_assembly.fasta | grep -q "circular"; then
            echo "Chromosome is fully resolved, trying to clean up the assembly..."
            clean_short_contigs "autocycler_out/consensus_assembly.fasta" "autocycler.clean.fasta"              
            # rename outputs
            mv autocycler.clean.fasta ${prefix}.autocycler.fasta
            mv autocycler_out/consensus_assembly.gfa ${prefix}.autocycler.gfa
            echo "SUCCESS" > RESULT 
        else
            echo "Chromosome is not fully resolved, assembly failed"
            finalize_output "autocycler_out/consensus_assembly" "${prefix}.autocycler"
            echo "FAIL" > RESULT       
        fi
    else
        echo "Autocycler failed to produce a consensus assembly"
        echo "FAIL" > RESULT
    fi  

    # get contig lengths
    echo "Autocycler" > ${prefix}.autocycler.ctg_len.txt
    awk -F'length=' '/^>/{split(\$2,a," "); print a[1]}' ${prefix}.autocycler.fasta | sort -nr >> ${prefix}.autocycler.ctg_len.txt
    """
}