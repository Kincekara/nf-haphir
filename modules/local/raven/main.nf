process RAVEN_ASM {

    tag "$meta.id"
    label 'process_high'
    container 'staphb/raven:1.8.3-noble'

    input:
    tuple val(meta), path(long_fq)

    output:
    tuple val(meta), path("*.fasta"), emit: asm
    tuple val(meta), path("*.gfa"), emit: asm_graph
    tuple val(meta), path("*.raven.ctg_len.txt"), emit: asm_ctg_len

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
    --identity 0.99 \\
    --polishing-rounds 1 \\
    --graphical-fragment-assembly ${prefix}.raven.gfa \\
    ${long_fq} > ${prefix}.raven.fasta

    # get contig lengths
    echo "Raven" > ${prefix}.raven.ctg_len.txt
    awk -F'LN:i:' '/^>/{split(\$2,a," "); print a[1]}' ${prefix}.raven.fasta | sort -nr >> ${prefix}.raven.ctg_len.txt

    # version control
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        raven: \$(raven --version)
    END_VERSIONS
    """
}