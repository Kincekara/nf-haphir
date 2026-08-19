process LJA_ASM {

    tag "$meta.id"
    container 'staphb/lja:0.2-bugfix'

    input:
    tuple val(meta), path(long_fq)

    output:
    tuple val(meta), path("*.lja.fasta"), emit: asm
    tuple val(meta), path("*.lja.gfa"), emit: asm_graph
    tuple val(meta), path("*.lja.ctg_len.txt"), emit: asm_ctg_len
    tuple val("${task.process}"), val('lja'), val("0.2"), emit: versions_lja, topic: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    lja \\
    -t ${task.cpus} \\
    -o out \\
    --reads ${long_fq} > lja.out.txt 2> lja.err.txt

    # rename output
    mv out/assembly.fasta ${prefix}.lja.fasta
    mv out/mdbg.gfa ${prefix}.lja.gfa

    # get contig lengths
    echo "LJA" > ${prefix}.lja.ctg_len.txt
    awk '/^>/ {if (len) print len; len=0; next} {len += length(\$0)} END {if (len) print len}' ${prefix}.lja.fasta | sort -nr >> ${prefix}.lja.ctg_len.txt

    """
}