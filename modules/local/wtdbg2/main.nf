process WTDBG2_ASM {

    tag "$meta.id"
    label 'process_high'
    container 'staphb/wtdbg2:2.5'

    input:
    tuple val(meta), path(long_fq), val(genome_size)

    output:
    tuple val(meta), path("*.fasta"), emit: asm

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    # assemble with wtdb2
    wtdbg2 \\
    -x ccs \\
    -t ${task.cpus} \\
    -i ${long_fq} \\
    -g ${genome_size} \\
    -o ${prefix}

    # derive consensus
    wtpoa-cns \\
    -t ${task.cpus} \\
    -i ${prefix}.ctg.lay.gz -fo ${prefix}.wtdbg2.fasta

    # version control
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        hifiasm: \$(wtdbg2 --version | cut -d " " -f2)
    END_VERSIONS
    """
}