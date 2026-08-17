process MERGE_ASMS {
    
    tag "$meta.id"
    label 'process_low'
    container 'quay.io/biocontainers/biopython:1.84'

    input:
    tuple val(meta), path(autocycler_asm), path(plassembler_asm), path(overlaps_paf)

    output:
    tuple val(meta), path("*.merged.fasta"), emit: merged_asm
    tuple val(meta), path("*.merge_summary.tsv"), emit: merge_summary
    tuple val("${task.process}"), val('biopython'), eval("python3 -c \"import Bio; print(Bio.__version__)\""), emit: versions_biopython, topic: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def args = task.ext.args ?: ""
    """
    merge_plasmids.py \\
    --autocycler ${autocycler_asm} \\
    --plassembler ${plassembler_asm} \\
    --paf ${overlaps_paf} \\
    --out ${prefix}.merged.fasta \\
    ${args}

    mv merge_summary.tsv ${prefix}.merge_summary.tsv

    # fix fasta headers
    sed -i 's/len=/length=/g' ${prefix}.merged.fasta   
    """
}