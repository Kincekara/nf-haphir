process AMRFINDER {

    tag "$meta.id"
    label 'process_medium'
    container 'staphb/ncbi-amrfinderplus:4.2.7-2026-03-24.1'

    input:
    tuple val(meta), path(assembly), path(bakta_faa), path(bakta_gff), val(organism)

    output:
    tuple val(meta), path("*.amrfinder.tsv"), emit: amrfinder_report

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    ## curated organisms ##
    # A. baumannii-calcoaceticus species complex
    declare -a abcc=(
        "Acinetobacter baumannii"
        "Acinetobacter calcoaceticus"
        "Acinetobacter lactucae"
        "Acinetobacter nosocomialis"
        "Acinetobacter pittii"
        "Acinetobacter seifertii"
    )
    # Burkholderia cepacia species complex
    declare -a bcc=(
        "Burkholderia aenigmatica"
        "Burkholderia ambifaria"   
        "Burkholderia anthina"   
        "Burkholderia arboris"   
        "Burkholderia catarinensis"   
        "Burkholderia cenocepacia"   
        "Burkholderia cepacia" 
        "Burkholderia cf. cepacia"  
        "Burkholderia contaminans"   
        "Burkholderia diffusa"   
        "Burkholderia dolosa"   
        "Burkholderia lata"   
        "Burkholderia latens"
        "Burkholderia metallica"  
        "Burkholderia multivorans"   
        "Burkholderia orbicola"   
        "Burkholderia paludis"   
        "Burkholderia pseudomultivorans"   
        "Burkholderia puraquae"   
        "Burkholderia pyrrocinia"   
        "Burkholderia semiarida"   
        "Burkholderia seminalis"   
        "Burkholderia sola"   
        "Burkholderia stabilis"   
        "Burkholderia stagnalis"   
        "Burkholderia territorii"   
        "Burkholderia ubonensis"   
        "Burkholderia vietnamiensis" 
    )
    # Burkholderia pseudomallei species complex
    declare -a bpc=(
        "Burkholderia humptydooensis"   
        "Burkholderia mallei"   
        "Burkholderia mayonis"   
        "Burkholderia oklahomensis"   
        "Burkholderia pseudomallei"   
        "Burkholderia savannae"   
        "Burkholderia singularis"   
        "Burkholderia thailandensis"   
    )
    # other species
    declare -a taxa=(   
        "Citrobacter freundii"
        "Clostridioides difficile"
        "Enterobacter asburiae"
        "Enterobacter cloacae"
        "Enterococcus faecalis"
        "Haemophilus influenzae"    
        "Klebsiella oxytoca"
        "Neisseria meningitidis"
        "Neisseria gonorrhoeae"
        "Pseudomonas aeruginosa" 
        "Serratia marcescens"  
        "Staphylococcus aureus"
        "Staphylococcus pseudintermedius"
        "Streptococcus agalactiae"
        "Streptococcus pyogenes"
        "Vibrio cholerae"
        "Vibrio parahaemolyticus"
        "Vibrio vulnificus"
    )

    # check organism in curated organism list
    genus=\$(echo "${organism}" | cut -d " " -f1)
    taxon=\$(echo "${organism}" | cut -d " " -f1,2)
    
    amrfinder_organism=""
    if [[ "\$genus" == "Acinetobacter" ]]; then
        for i in "\${abcc[@]}"; do
            if [[ "\$taxon" == "\$i" ]]; then
                amrfinder_organism="Acinetobacter_baumannii"
                break
            fi
        done
    elif [[ "\$genus" == "Burkholderia" ]]; then
        for i in "\${bcc[@]}"; do
            if [[ "\$taxon" == "\$i" ]]; then
                amrfinder_organism="Burkholderia_cepacia"
            break
            fi
        done
        for i in "\${bpc[@]}"; do
            if [[ "\$taxon" == "\$i" ]]; then
                amrfinder_organism="Burkholderia_pseudomallei"
                break
            fi
        done
    elif [[ "\$genus" == "Shigella" ]] || [[ "\$genus" == "Escherichia" ]]; then
        amrfinder_organism="Escherichia"
    elif [[ "\$genus" == "Salmonella" ]]; then
        amrfinder_organism="Salmonella"
    elif [[ "\$taxon" == "Campylobacter coli" ]] || [[ "\$taxon" == "Campylobacter jejuni" ]]; then
        amrfinder_organism="Campylobacter"
    elif [[ "\$taxon" == "Enterococcus faecium" ]] || [[ "\$taxon" == "Enterococcus hirae" ]]; then
        amrfinder_organism="Enterococcus_faecium"
    elif [[ "\$taxon" == "Klebsiella pneumoniae" ]] || [[ "\$taxon" == "Klebsiella aerogenes" ]]; then
        amrfinder_organism="Klebsiella_pneumoniae"
    elif [[ "\$taxon" == "Streptococcus pneumoniae" ]] || [[ "\$taxon" == "Streptococcus mitis" ]]; then
        amrfinder_organism="Streptococcus_pneumoniae"
    else    
        for i in "\${taxa[@]}"; do
            if [[ "\$taxon" == "\$i" ]]; then
                amrfinder_organism=\${taxon// /_}
                break
            fi
        done
    fi

    # checking bash variable
    echo "amrfinder organism is set to: \${amrfinder_organism}"

    # run amrfinderplus
    amrfinder \\
    --threads ${task.cpus} \\
    --plus \\
    --organism "\$amrfinder_organism" \\
    --name ${prefix} \\
    --nucleotide ${assembly} \\
    --protein ${bakta_faa} \\
    --gff ${bakta_gff} \\
    --annotation_format bakta \\
    -o ${prefix}.amrfinder.tsv

    # version control
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        amrfinderplus: \$(amrfinder --version)
        amrfinderplus_db: \$(amrfinder --database_version | grep "Database version" | awk -F': ' '{print \$2}')
    END_VERSIONS
    """
}