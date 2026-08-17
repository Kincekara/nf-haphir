process HICANU_ASM {

    tag "$meta.id"
    container 'staphb/canu:2.3'

    input:
    tuple val(meta), path(long_fq), val(genome_size)

    output:
    tuple val(meta), path("*.hicanu.fasta"), emit: asm
    tuple val(meta), path("*.hificanu.ctg_len.txt"), emit: asm_ctg_len
    tuple val("${task.process}"), val('canu'), eval("canu --version | cut -d ' ' -f 2"), emit: versions_canu, topic: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    canu \\
    -p ${prefix} \\
    -d out \\
    genomeSize=${genome_size} \\
    -pacbio-hifi ${long_fq} \\
    useGrid=false \\
    maxThreads=${task.cpus}

    # get contig lengths
    mv out/${prefix}.contigs.fasta ${prefix}.hicanu.fasta
    echo "HiCanu" > ${prefix}.hicanu.ctg_len.txt
    awk -F"len=| " '/^>/{print \$3}' ${prefix}.hicanu.fasta | sort -nr >> ${prefix}.hicanu.ctg_len.txt
    """
}