process DOWNSAMPLE {

    tag "$meta.id"
    label 'process_low'
    container 'staphb/rasusa:4.1.0'

    input:
    tuple val(meta), path(long_fq), val(genome_size)

    output:
    tuple val(meta), path("*.downsampled.fastq.gz"), emit: downsampled_fq
    tuple val("${task.process}"), val('rasusa'), eval("rasusa --version | cut -d ' ' -f 2"), emit: versions_rasusa, topic: versions

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

    """
}
