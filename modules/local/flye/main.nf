process FLYE_ASM {

    tag "$meta.id"
    label 'process_high'
    container 'staphb/flye:2.9.6'

    input:
    tuple val(meta), path(long_fq), val(genome_size)

    output:
    tuple val(meta), path("*.flye.fasta"), emit: asm
    tuple val(meta), path("*.flye.gfa"), emit: asm_graph
    tuple val(meta), path("*.flye_info.txt"), emit: asm_info

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    # assemble with flye
    flye \\
    --threads ${task.cpus} \\
    --pacbio-hifi ${long_fq} \\
    --genome-size ${genome_size} \\
    --out-dir flye_out

    # rename outputs
    mv ./flye_out/assembly.fasta ${prefix}.flye.fasta
    mv ./flye_out/assembly_graph.gfa ${prefix}.flye.gfa
    mv ./flye_out/assembly_info.txt ${prefix}.flye_info.txt

    # version control
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        flye: \$(flye --version)
    END_VERSIONS
    """



}