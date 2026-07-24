process ASM_VISUALIZATION {
    
    tag "$meta.id"
    label 'process_low'
    container 'staphb/bandage:0.9.0'

    input:
    tuple val(meta), path(hifiasm_gfa), path(flye_gfa), path(raven_gfa), path(wtdbg2_asm), path(autocycler_gfa), path(plassembler_gfa), path(final_asm),
    path(hifiasm_ctg_len), path(flye_ctg_len), path(raven_ctg_len), path(wtdbg2_ctg_len), path(autocycler_ctg_len), path(plassembler_ctg_len), path(final_ctg_len)

    output:
    tuple val(meta), path("*.bandage.html"), emit: bandage_viz
    tuple val("${task.process}"), val('bandage'), eval("Bandage --version | cut -d ' ' -f2"), emit: versions_bandage, topic: versions

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
    if [ -s "${plassembler_gfa}" ]; then
        Bandage image ${plassembler_gfa} plassembler.png
    fi
    Bandage image ${final_asm} final.png

    # create tables of contig lengths
    if [ -s "${plassembler_ctg_len}" ]; then
        paste ${hifiasm_ctg_len} ${flye_ctg_len} ${raven_ctg_len} ${wtdbg2_ctg_len} ${autocycler_ctg_len} ${plassembler_ctg_len} ${final_ctg_len} > ctg_len_table.txt
    else
        paste ${hifiasm_ctg_len} ${flye_ctg_len} ${raven_ctg_len} ${wtdbg2_ctg_len} ${autocycler_ctg_len} ${final_ctg_len} > ctg_len_table.txt
    fi

    create_len_table.sh ctg_len_table.txt table

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
                table {font-family: arial, sans-serif; border-collapse: collapse; width: 100%; }
                td, th { border: 1px solid #dddddd; text-align: left; padding: 6px; }
                tr:nth-child(even) {  background-color: #dddddd; }
            </style>            
        </head>
        <body>
            <h1>Assembly Comparison</h1>
            <h2>Intermediate Assemblies</h2>
            <div class="grid">
                <div class="grid-item">
                    <div class="caption">Hifiasm</div>
                    <img src="data:image/png;base64,\$(base64 -w 0 hifiasm.png)" alt="Hifiasm" />
                </div>
                <div class="grid-item">
                    <div class="caption">Flye</div>
                    <img src="data:image/png;base64,\$(base64 -w 0 flye.png)" alt="Flye" />
                </div>
                <div class="grid-item">
                    <div class="caption">Raven</div>
                    <img src="data:image/png;base64,\$(base64 -w 0 raven.png)" alt="Raven" />
                </div>
                <div class="grid-item">
                    <div class="caption">Wtdbg2</div>
                    <img src="data:image/png;base64,\$(base64 -w 0 wtdbg2.png)" alt="Wtdbg2" />
                </div>
                <div class="grid-item">
                    <div class="caption">Autocycler</div>
                    <img src="data:image/png;base64,\$(base64 -w 0 autocycler.png)" alt="Autocycler" />
                </div>
                <!--<div class="grid-item">
                    <div class="caption">Plassembler</div>
                    <img src="data:image/png;base64,\$(base64 -w 0 plassembler.png)" alt="Plassembler">
                </div>-->
            </div>
            <br><br>
            <h2>Contig Lengths</h2>
            <div class="table">
                \$(cat table)
                </div>
            <br><br>
            <h2>Final Assembly</h2>
            <img src="data:image/png;base64,\$(base64 -w 0 final.png)" alt="final_asm">                
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

    """
}