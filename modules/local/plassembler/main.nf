process PLASSEMBLER_ASM {
    
    tag "$meta.id"
    label 'process_high'
    container 'staphb/plassembler:1.8.2'

    input:
    tuple val(meta), path (long_fq), path(short_fq1), path(short_fq2), path(flye_asm), path(flye_info)

    output:
    tuple val(meta), path("out/*_plasmids.fasta"), emit: asm
    tuple val(meta), path("out/*_plasmids.gfa"), emit: asm_graph
    tuple val(meta), path("out/*_summary.tsv"), emit: summary

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    # plassembler
    plassembler run \\
    --threads ${task.cpus} \\
    --database /plassembler_db \\
    --pacbio_model pacbio-hifi \\
    --longreads ${long_fq} \\
    --short_one ${short_fq1} \\
    --short_two ${short_fq2} \\
    --flye_assembly ${flye_asm} \\
    --flye_info ${flye_info} \\
    --skip_qc \\
    --prefix ${prefix} \\
    --outdir out

    # version control
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        plassembler: \$(plassembler --version | cut -d " " -f3 | tr -d "\\n")
    END_VERSIONS
    """
}