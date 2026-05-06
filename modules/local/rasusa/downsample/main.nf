process DOWNSAMPLE {

    tag "$meta.id"
    label 'process_medium'
    container 'staphb/rasusa:4.1.0'

    input:
    tuple val(meta), val(genome_size), path(long_fq)

    output:
    tuple val(meta), path("*.downsampled.fastq.gz"), emit: downsampled_fq

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    # downsample reads
    rasusa reads \\
    --seed 42 \\
    --coverage 110 \\
    --genome-size ${genome_size} \
    --output ${prefix}.downsampled.fastq.gz \
    --output-format fastq \\
    ${long_fq}

    # version control
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        rasusa: \$(rasusa --version)
    END_VERSIONS
    """
}
