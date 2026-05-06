process ASM_VISUALIZATION {
    
    tag "$meta.id"
    label 'process_low'
    container 'staphb/bandage:0.9.0'

    input:
    tuple val(meta), path(hifiasm_gfa), path(flye_gfa), path(raven_gfa), path(wtdbg2_asm), path(autocycler_gfa), path(plassembler_gfa), path(final_asm)

    output:
    tuple val(meta), path("*.bandage.html"), emit: bandage_viz

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    # Bandage
    Bandage image ${hifiasm_gfa} hifiasm.png
    Bandage image ${flye_gfa} flye.png
    Bandage image ${raven_gfa} raven.png
    Bandage image ${wtdbg2_asm} wtdbg2.png
    Bandage image ${autocycler_gfa} autocycler.png
    if [ -n "${plassembler_gfa}" ]; then
        Bandage image ${plassembler_gfa} plassembler.png
    fi
    Bandage image ${final_asm} final.png

    # write html file
    cat << EOF > ${prefix}.bandage.html
    <html>
        <head>
            <title>${prefix}</title>
            <meta charset="utf-8" />
            <style>
                body { font-family: Arial, sans-serif; margin: 20px; }
                h1 { margin-bottom: 16px; text-align: center; }
                .grid { display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 16px; width: 100%; }
                .grid-item { border: 1px solid #ccc; padding: 10px; }
                .grid-item .caption { margin-top: 8px; font-weight: bold; text-align: center; }
                img { max-width: 100%; height: auto; display: block; margin: 0 auto; }
            </style>            
        </head>
        <body>
            <h1>Assembly Comparison</h1>
            <h2>Intermediate Assemblies</h2>
            <div class="grid">
                <div class="grid-item">
                    <div class="caption">Hifiasm</div>
                    <img src="data:image/png;base64,$(base64 -w 0 hifiasm.png)" alt="Hifiasm" />
                </div>
                <div class="grid-item">
                    <div class="caption">Flye</div>
                    <img src="data:image/png;base64,$(base64 -w 0 flye.png)" alt="Flye" />
                </div>
                <div class="grid-item">
                    <div class="caption">Raven</div>
                    <img src="data:image/png;base64,$(base64 -w 0 raven.png)" alt="Raven" />
                </div>
                <div class="grid-item">
                    <div class="caption">Wtdbg2</div>
                    <img src="data:image/png;base64,$(base64 -w 0 wtdbg2.png)" alt="Wtdbg2" />
                </div>
                <div class="grid-item">
                    <div class="caption">Autocycler</div>
                    <img src="data:image/png;base64,$(base64 -w 0 autocycler.png)" alt="Autocycler" />
                </div>
                <!--<div class="grid-item">
                    <div class="caption">Plassembler</div>
                    <img src="data:image/png;base64,$(base64 -w 0 plassembler.png)" alt="Plassembler">
                </div>-->
            </div>
            <br><br>
            <h2>Final Assembly</h2>
            <img src="data:image/png;base64,$(base64 -w 0 final.png)" alt="final_asm">                
        </body>
        <hr>
        <footer>
        <p><i>This report is created by <a href="https://github.com/Kincekara/haphir">HAPHiR</a> bioinformatics pipeline.</br></i></p>
        </footer>
    </html>
    EOF

    if [ -f plassembler.png ]; then
        sed -i 's/<!--//g; s/-->//g' ${prefix}.bandage.html
    fi

    # version control
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bandage: \$(Bandage --version | cut -d " " -f2)
    END_VERSIONS
    """
}