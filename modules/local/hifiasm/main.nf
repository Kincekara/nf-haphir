process HIFIASM_ASM {

    tag "$meta.id"
    container 'staphb/hifiasm:0.25.0'

    input:
    tuple val(meta), path(long_fq), val(genome_size)

    output:
    tuple val(meta), path("*.hifiasm.fasta"), emit: asm
    tuple val(meta), path("*.hifiasm.gfa"), emit: asm_graph
    tuple val(meta), path("*.hifiasm.ctg_len.txt"), emit: asm_ctg_len
    tuple val("${task.process}"), val('hifiasm'), eval("hifiasm --version"), emit: versions_hifiasm, topic: versions

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
    awk '/^S/{print ">"\$2" length="length(\$3);print \$3}' ${prefix}.hifiasm.gfa > ${prefix}.hifiasm.fasta

    # get contig lengths
    echo "Hifiasm" > ${prefix}.hifiasm.ctg_len.txt
    awk -F'length=' '/^>/{print \$2}' ${prefix}.hifiasm.fasta | sort -nr >> ${prefix}.hifiasm.ctg_len.txt

    """
}