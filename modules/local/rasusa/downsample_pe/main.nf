process DOWNSAMPLE_PE {

    tag "$meta.id"
    label 'process_medium'
    container 'staphb/rasusa:4.1.0'

    input:
    tuple val(meta), val(genome_size), path(reads)

    output:
    tuple val(meta), path("*.r{1,2}.fastq.gz"), emit: short_fqs

    when:
    task.ext.when == null || task.ext.when

    script:
    def short_fq1 = reads[0]
    def short_fq2 = reads[1]
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    # downsample pe reads
    rasusa reads \\
    --seed 42 \\
    --coverage 110 \\
    --genome-size ${genome_size} \\
    -o ${prefix}.downsampled.r1.fastq.gz \\
    -o ${prefix}.downsampled.r2.fastq.gz \\
    ${short_fq1} ${short_fq2}

    # version control
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        rasusa: \$(rasusa --version)
    END_VERSIONS
    """
}
