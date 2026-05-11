process TRIM_PE {
    
    tag "$meta.id"
    label 'process_medium'
    container 'staphb/fastp:1.3.2'

    input:
    tuple val(meta), path(short_fq1), path(short_fq2)

    output:
    tuple val(meta), path("*.trimmed.fq1.gz"), path("*.trimmed.fq2.gz"), emit: trimmed_short_fqs
    tuple val(meta), path("*.fastp.html"), emit: fastp_report

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    # trim reads with fastp
    fastp \\
    -i ${short_fq1} \\
    -I ${short_fq2} \\
    -o ${prefix}.trimmed.fq1.gz \\
    -O ${prefix}.trimmed.fq2.gz \\
    --length_required 70 \\
    --average_qual 30 \\
    --cut_front_window_size 1 \\
    --cut_front_mean_quality 10 \\
    -3 \\
    --cut_tail_window_size 1 \\
    --cut_tail_mean_quality 10 \\
    -r \\
    --cut_right_window_size 4 \\
    --cut_right_mean_quality 20 \\
    --detect_adapter_for_pe \\
    --thread ${task.cpus} \\
    -h ${prefix}.fastp.html

    # version control
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fastp: \$(fastp --version | cut -d " " -f2)
    END_VERSIONS
    """
}