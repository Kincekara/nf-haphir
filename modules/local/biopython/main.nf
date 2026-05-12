process MERGE_ASMS {
    
    tag "$meta.id"
    label 'process_low'
    container 'quay.io/biocontainers/biopython:1.84'

    input:
    tuple val(meta), path(autocycler_asm), path(plassembler_asm), path(overlaps_paf)

    output:
    tuple val(meta), path("*.merged.fasta"), emit: merged_asm

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

    # version control
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        biopython: \$(python3 -c "import Bio; print(Bio.__version__)")
    END_VERSIONS
    """
}