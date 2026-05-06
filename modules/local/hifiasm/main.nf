process HIFIASM_ASM {

    tag "$meta.id"
    label 'process_high'
    container 'staphb/hifiasm:0.25.0'

    input:
    tuple val(meta), path(long_fq), val(genome_size)

    output:
    tuple val(meta), path("*.hifiasm.fasta"), emit: asm
    tuple val(meta), path("*.hifiasm.gfa"), emit: asm_graph

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    # assemble with hifiasm
    hifiasm \\
    -o ${prefix} \\
    -t ${task.cpus} \\
    --hg-size ${genome_size} \\
    ${long_fq} 2> hifiasm.log

    # gfa to fasta
    mv ${prefix}.bp.p_ctg.gfa ${prefix}.hifiasm.gfa
    awk '/^S/{print ">"\$2;print \$3}' ${prefix}.hifiasm.gfa > ${prefix}.hifiasm.fasta

    # version control
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        hifiasm: \$(hifiasm --version)
    END_VERSIONS
    """
}