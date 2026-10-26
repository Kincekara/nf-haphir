process FILTER {

    tag "$meta.id"
    container 'staphb/tgsfilter:1.11'

    input:
    tuple val(meta), path(long_fq)

    output:
    tuple val(meta), path("*.fastq.gz"), emit: filtered_fq
    tuple val(meta), path("*.html"), emit: html_report
    tuple val(meta), path("*.log"), emit: tgsfilter_log
    tuple val("${task.process}"), val('tgsfilter'), eval("tgsfilter -h | tail -n2 |  grep -oE '[0-9]+\\.[0-9]+'"), emit: versions_tgsfilter, topic: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def min_length = task.ext.args // set 0 to disable length filtering, default 1000
    def bias = 100 // set 100 to disable base content bias correction, default 1
    """
    # adapter filter & qc
    tgsfilter \\
    -t ${task.cpus} \\
    -x hifi \\
    -l ${min_length} \\
    -b ${bias} \\
    -i ${long_fq} \\
    -o ${prefix}.filtered.fastq.gz 2>&1 | tee ${prefix}.tgsfilter.log

    # rename html report
    mv ${prefix}.filtered.html ${prefix}.tgsfilter.html
    """
}