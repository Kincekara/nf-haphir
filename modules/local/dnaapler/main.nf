process REORIENT {
    
    tag "$meta.id"
    label 'process_medium'
    container 'staphb/dnaapler:1.3.0'

    input:
    tuple val(meta), path(long_asm)

    output:
    tuple val(meta), path("*.fasta"), emit: reoriented_asm
    tuple val(meta), path("*.dnaapler_summary.tsv"), emit: dnaapler_summary
    tuple val(meta), path("*.ctg_len.txt"), emit: asm_ctg_len
    tuple val("${task.process}"), val('dnaapler'), eval("dnaapler --version | cut -d ' ' -f3"), emit: versions_dnaapler, topic: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    # reorient assembly with dnaapler
    dnaapler all \\
    -i ${long_asm} \\
    -o out \\
    -t ${task.cpus} \\
    # rename output
    mv out/dnaapler_reoriented.fasta ${prefix}.fasta
    mv out/dnaapler_all_reorientation_summary.tsv ${prefix}.dnaapler_summary.tsv 

    # get contig lengths
    echo "Final" > ${prefix}.ctg_len.txt
    awk -F'length=' '/^>/{split(\$2,a," "); print a[1]}' ${prefix}.fasta | sort -nr >> ${prefix}.ctg_len.txt

    """
}