process ANNOTATION {
    
    tag "$meta.id"
    label 'process_medium'
    container 'staphb/bakta:1.12.0-6.0-light'

    input:
    tuple val(meta), path(final_asm), val(organism)

    output:
    tuple val(meta), path("*.fna"), path("*.faa"), path("*.gff3"), emit: bakta
    tuple val(meta), path("*.bakta.tar.gz"), emit: bakta_output

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    # annotate with bakta
    if [ -n "${organism}" ]; then
        genus=\$(echo ${organism} | cut -d ' ' -f1)
        species=\$(echo ${organism} | cut -d ' ' -f2)

        bakta \
        --threads ${task.cpus} \\
        --prefix ${prefix} \\
        --complete \\
        --compliant \\
        --output bakta \\
        --genus "\$genus" \\
        --species "\$species" \\
        ${final_asm}
    else
        bakta \\
        --threads ${task.cpus} \\
        --prefix ${prefix} \\
        --complete \\
        --compliant \\
        --output bakta \\
        ${final_asm}
    fi

    # compress outputs
    tar -czvf ${prefix}.bakta.tar.gz bakta/

    # version control
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bakta: \$(bakta --version | cut -d " " -f2)
    END_VERSIONS
    """
}