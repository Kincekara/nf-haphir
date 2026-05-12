process ESTIMATE_GENOME_SIZE {

    tag "$meta.id"
    label 'process_medium'
    container 'staphb/lrge:0.3.0'

    input:
    tuple val(meta), path(long_fq)

    output:
    tuple val(meta), env("GSIZE"), emit: gsize

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

    # version control
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        lrge: \$(lrge --version | cut -d " " -f2)
    END_VERSIONS
    """
}