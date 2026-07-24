process ESTIMATE_GENOME_SIZE {

    tag "$meta.id"
    label 'process_medium'
    container 'staphb/lrge:0.3.0'

    input:
    tuple val(meta), path(long_fq)

    output:
    tuple val(meta), env("GSIZE"), emit: gsize
    tuple val("${task.process}"), val('lrge'), eval("lrge --version | cut -d ' ' -f2"), emit: versions_lrge, topic: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    # find genome size
    lrge \\
    -P pb \\
    -t ${task.cpus} \\
    -o gsize.txt \\
    ${long_fq}   

    # round genome size
    GSIZE=\$(printf "%dm\\n" \$(( (\$(cat gsize.txt) +500000)/1000000 ))) 

    """
}