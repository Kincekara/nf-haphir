process POLISH {
    
    tag "$meta.id"
    label 'process_medium'
    container 'staphb/polypolish:0.6.1-bwa'

    input:
    tuple val(meta), path(draft_asm), path(short_fq1), path(short_fq2)

    output:
    tuple val(meta), path("*.polished.fasta"), emit: polished_asm

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    # index    
    bwa index ${draft_asm}
    # map
    bwa mem -t ${task.cpus} -a ${draft_asm} ${short_fq1} > alignments_1.sam
    bwa mem -t ${task.cpus} -a ${draft_asm} ${short_fq2} > alignments_2.sam
    # filter
    if polypolish filter --in1 alignments_1.sam --in2 alignments_2.sam --out1 filtered_1.sam --out2 filtered_2.sam; then
        # polish with filtered alignments
        polypolish polish ${draft_asm} filtered_1.sam filtered_2.sam > ${prefix}.polished.fasta
    else
        # polish with unfiltered alignments if filter fails
        polypolish polish ${draft_asm} alignments_1.sam alignments_2.sam > ${prefix}.polished.fasta
    fi

    # version control
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        polypolish: \$(polypolish --version | cut -d " " -f2)
    END_VERSIONS
    """
}