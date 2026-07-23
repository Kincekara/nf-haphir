process PLASSEMBLER_ASM_LONG {
    
    tag "$meta.id"
    label 'process_high'
    container 'staphb/plassembler:1.8.3'

    input:
    tuple val(meta), path (long_fq), path(flye_asm), path(flye_info)

    output:
    tuple val(meta), path("out/*_plasmids.fasta"), emit: asm
    tuple val(meta), path("out/*_plasmids.gfa"), emit: asm_graph
    tuple val(meta), path("out/*_summary.tsv"), emit: summary
    tuple val(meta), path("*.plassembler.ctg_len.txt"), emit: asm_ctg_len

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    # plassembler
    plassembler long \\
    --threads ${task.cpus} \\
    --database /plassembler_db \\
    --pacbio_model pacbio-hifi \\
    --longreads ${long_fq} \\
    --flye_assembly ${flye_asm} \\
    --flye_info ${flye_info} \\
    --skip_qc \\
    --prefix ${prefix} \\
    --outdir out 

    # get contig lengths
    echo "Plassembler" > ${prefix}.plassembler.ctg_len.txt
    awk 'NR > 1 {print \$2}' out/${prefix}_summary.tsv >> ${prefix}.plassembler.ctg_len.txt

    # version control
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        plassembler: \$(plassembler --version | cut -d " " -f3 | tr -d "\\n")
    END_VERSIONS
    """
}