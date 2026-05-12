process COMBINE_ASMS {

    tag "$meta.id"
    label 'process_high'
    container 'staphb/autocycler:0.6.2'

    input:
    tuple val(meta), path(hifiasm_asm), path(flye_asm), path(wtdbg2_asm), path(raven_asm)

    output:
    tuple val(meta), path("*.autocycler.fasta"), emit: asm
    tuple val(meta), path("*.autocycler.gfa"), emit: asm_graph

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    # collect assemblies
    mkdir assemblies
    cp ${hifiasm_asm} ${flye_asm} ${wtdbg2_asm} ${raven_asm} assemblies/
    # compress
    autocycler compress -i assemblies -a autocycler_out
    # cluster
    autocycler cluster -a autocycler_out
    # trim and resolve
    for c in autocycler_out/clustering/qc_pass/cluster_*; do
        autocycler trim -c "\$c"
        autocycler resolve -c "\$c"
    done
    # combine
    autocycler combine -a autocycler_out -i autocycler_out/clustering/qc_pass/cluster_*/5_final.gfa

    # rename outputs
    mv autocycler_out/consensus_assembly.fasta ${prefix}.autocycler.fasta
    mv autocycler_out/consensus_assembly.gfa ${prefix}.autocycler.gfa

    # version control
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        autocycler: \$(autocycler --version | cut -d " " -f2)
    END_VERSIONS
    """
}