process ASM_QC_LONG {

    tag "$meta.id"
    label 'process_medium'
    container 'staphb/merqury:1.4.1'

    input:
    tuple val(meta), path(asm), path(long_fq)

    output:    
    tuple val(meta), path("*.html"), emit: merqury_html
    tuple val(meta), path("logs/*.log"), emit: merqury_log
    tuple val(meta), path("*.qv"), path("*.completeness.stats"), path("EVAL.txt"), emit: merqury_stats
    tuple val("${task.process}"), val('merqury'), val("1.4.1"), emit: versions_merqury, topic: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def version = "v${workflow.manifest.version}"
    """
    # meryl count
    meryl count threads=${task.cpus} k=19 ${long_fq} output reads.meryl

    # merqury
    merqury.sh reads.meryl ${asm} ${prefix}

    # evaluate
    evaluate_asm.sh ${prefix}.qv ${prefix}.completeness.stats hifi

    # create html report
    create_qc_tables.sh ${prefix}.qv ${prefix}.completeness.stats

    cat << EOF > ${prefix}.merqury.html
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
                table {font-family: arial, sans-serif; border-collapse: collapse; }
                td, th { border: 1px solid #dddddd; text-align: left; padding: 6px; }
                tr:nth-child(even) {  background-color: #dddddd; }
            </style>            
        </head>
        <body>
            <h1>Assembly Quality Control Report</h1>
            <h2>Reference free QV estimation</h2>
            <table>
                <tr>
                    <th>Assembly</th>
                    <th>Num. of unique k-mers</th>
                    <th>Num. of k-mers</th>
                    <th>QV</th>
                    <th>Error rate</th>
                </tr>
                \$(cat qv_table)
            </table>
            <br><br>

            <h2>K-mer Completeness</h2>
            <table>
                <tr>
                    <th>Assembly</th>
                    <th>Read set</th>
                    <th>Num. of solid k-mers (asm)</th>
                    <th>Num. of solid k-mers (reads)</th>
                    <th>Completeness (%)</th>
                </tr>
                \$(cat comp_table)
            </table>
            <br><br>
            
            <h2>Copy-number spectrum</h2>
            <div class="grid">
                <div class="grid-item">
                    <div class="caption">stacked</div>
                    <img src="data:image/png;base64,\$(base64 -w 0 ${prefix}.${prefix}.spectra-cn.st.png)" alt=stacked />
                </div>
                <div class="grid-item">
                    <div class="caption">filled</div>
                    <img src="data:image/png;base64,\$(base64 -w 0 ${prefix}.${prefix}.spectra-cn.fl.png)" alt=filled />
                </div>
                <div class="grid-item">
                    <div class="caption">line</div>
                    <img src="data:image/png;base64,\$(base64 -w 0 ${prefix}.${prefix}.spectra-cn.ln.png)" alt=line />
                </div>
            </div>
            <h2>Assembly spectrum</h2>
            <div class="grid">
                <div class="grid-item">
                    <div class="caption">stacked</div>
                    <img src="data:image/png;base64,\$(base64 -w 0 ${prefix}.spectra-asm.st.png)" alt=stacked />
                </div>
                <div class="grid-item">
                    <div class="caption">filled</div>
                    <img src="data:image/png;base64,\$(base64 -w 0 ${prefix}.spectra-asm.fl.png)" alt=filled />
                </div>
                <div class="grid-item">
                    <div class="caption">line</div>
                    <img src="data:image/png;base64,\$(base64 -w 0 ${prefix}.spectra-asm.ln.png)" alt=line />
                </div>
            </div>
            <br><br>
        </body>
        <hr>
        <footer>
        <p><i>This report is created by <a href="https://github.com/Kincekara/nf-haphir">nf-HAPHiR ${version}</a> bioinformatics pipeline.</br></i></p>
        </footer>
    </html>
    EOF

    """
}