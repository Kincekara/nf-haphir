process LABEL_AND_ALIGN {
    
    tag "$meta.id"
    label 'process_low'
    container 'staphb/minimap2:2.30'

    input:
    tuple val(meta), path(autocycler_asm), path(plassembler_asm)

    output:
    tuple val(meta), path("*.autocycler.marked.fasta"), path("*.plasmids.marked.fasta"), path("*.overlaps.paf"), emit: overlaps
    tuple val("${task.process}"), val('minimap2'), eval("minimap2 --version"), emit: versions_minimap2, topic: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    # modify headers
    mark_headers.sh ${autocycler_asm} ${prefix}.autocycler.marked.fasta "autocycler"
    mark_headers.sh ${plassembler_asm} ${prefix}.plasmids.marked.fasta "plassembler"

    # align with minimap2
    minimap2 -x asm5 ${prefix}.autocycler.marked.fasta ${prefix}.plasmids.marked.fasta > ${prefix}.overlaps.paf
    """
}