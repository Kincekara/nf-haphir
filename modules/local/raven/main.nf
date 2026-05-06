process RAVEN_ASM {

    tag "$meta.id"
    label 'process_high'
    container 'staphb/raven:1.8.3-noble'

    input:
    tuple val(meta), path(long_fq), val(genome_size)

    output:
    tuple val(meta), path("*.fasta"), emit: asm
    tuple val(meta), path("*.gfa"), emit: asm_graph

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    # assemble with raven
    raven \\
    --threads ${task.cpus} \\
    --kmer-len 29 \\
    --window-len 9 \\
    --graphical-fragment-assembly ${prefix}.raven.gfa \\
    ${long_fq} > ${prefix}.raven.fasta

    # version control
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        hifiasm: \$(raven --version)
    END_VERSIONS
    """
}