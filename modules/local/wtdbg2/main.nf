process WTDBG2_ASM {

    tag "$meta.id"
    label 'process_high'
    container 'staphb/wtdbg2:2.5-noble'

    input:
    tuple val(meta), path(long_fq), val(genome_size)

    output:
    tuple val(meta), path("*.fasta"), emit: asm
    tuple val(meta), path("*.wtdbg2.ctg_len.txt"), emit: asm_ctg_len
    tuple val("${task.process}"), val('wtdbg2'), eval("wtdbg2 --version | cut -d ' ' -f2"), emit: versions_wtdbg2, topic: versions

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
    -o ${prefix} \\
    -S 2

    # derive consensus
    wtpoa-cns \\
    -t ${task.cpus} \\
    -i ${prefix}.ctg.lay.gz -fo ${prefix}.wtdbg2.fasta

    # get contig lengths
    echo "Wtdbg2" > ${prefix}.wtdbg2.ctg_len.txt
    awk -F'len=' '/^>/{print \$2}' ${prefix}.wtdbg2.fasta | sort -nr >> ${prefix}.wtdbg2.ctg_len.txt

    """
}