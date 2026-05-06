process LABEL_AND_ALIGN {
    
    tag "$meta.id"
    label 'process_low'
    container 'staphb/minimap2:2.30'

    input:
    tuple val(meta), path(autocycler_asm), path(plassembler_asm)

    output:
    tuple val(meta), path("*.overlaps.paf"), emit: paf
    tuple val(meta), path("*.autocycler.marked.fasta"), emit: ac_marked
    tuple val(meta), path("*.plasmids.marked.fasta"), emit: pl_marked

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

    # version control
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        minimap2: \$(minimap2 --version)
    END_VERSIONS
    """
}