/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { paramsSummaryMap       } from 'plugin/nf-schema'
include { softwareVersionsToYAML } from '../../subworkflows/nf-core/utils_nfcore_pipeline'
include { ESTIMATE_GENOME_SIZE   } from '../../modules/local/lrge/'
include { DOWNSAMPLE             } from '../../modules/local/rasusa/downsample'
include { DOWNSAMPLE_PE          } from '../../modules/local/rasusa/downsample_pe'
include { FLYE_ASM               } from '../../modules/local/flye/'
include { HIFIASM_ASM            } from '../../modules/local/hifiasm/'
include { RAVEN_ASM              } from '../../modules/local/raven/'
include { WTDBG2_ASM             } from '../../modules/local/wtdbg2/'
include { COMBINE_ASMS           } from '../../modules/local/autocycler/'
include { TRIM_PE                } from '../../modules/local/fastp/'
include { PLASSEMBLER_ASM        } from '../../modules/local/plassembler/'
include { LABEL_AND_ALIGN        } from '../../modules/local/minimap2/'
include { MERGE_ASMS             } from '../../modules/local/biopython/'
include { POLISH                 } from '../../modules/local/polypolish/'
include { REORIENT               } from '../../modules/local/dnaapler/'
include { ASM_VISUALIZATION      } from '../../modules/local/bandage/'
include { ANNOTATION             } from '../../modules/local/bakta/'
include { AMRFINDER              } from '../../modules/local/amrfinderplus/'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow HAPHIR {
    take:
    ch_samplesheet // channel: samplesheet read in from --input

    main:

    def ch_versions = channel.empty()

    //
    // Collate and save software versions
    //
    def topic_versions = channel.topic("versions")
        .distinct()
        .branch { entry ->
            versions_file: entry instanceof Path
            versions_tuple: true
        }

    def topic_versions_string = topic_versions.versions_tuple
        .map { process, tool, version ->
            [process[process.lastIndexOf(':') + 1..-1], "  ${tool}: ${version}"]
        }
        .groupTuple(by: 0)
        .map { process, tool_versions ->
            tool_versions.unique().sort()
            "${process}:\n${tool_versions.join('\n')}"
        }

    def ch_collated_versions = softwareVersionsToYAML(ch_versions.mix(topic_versions.versions_file))
        .mix(topic_versions_string)
        .collectFile(
            storeDir: "${params.outdir}/pipeline_info",
            name: 'nf-haphir_software_' + 'versions.yml',
            sort: true,
            newLine: true,
        )

    def criteria = multiMapCriteria {
    meta, data ->
        def long_fq   = data[0]
        def short_fq1 = data.size() >= 3 ? data[1] : null
        def short_fq2 = data.size() >= 3 ? data[2] : null
        def organism  = data.size() == 4 ? data[3] : null

        short_fqs:  meta.hybrid ? tuple(meta, short_fq1, short_fq2) : tuple(meta, null, null)
        long_fq:    long_fq ? tuple(meta, long_fq) : tuple(meta, null)
        organism:   meta.organism ? tuple(meta, organism) : tuple(meta, null)
    }

    ch_samplesheet
        .multiMap (criteria)
        .set { ch_input }
    
    // Genome size estimation
    ESTIMATE_GENOME_SIZE(ch_input.long_fq)

    // Downsampling
    DOWNSAMPLE(
        ch_input.long_fq
        .join(ESTIMATE_GENOME_SIZE.out.gsize)
        )

    // Flye assembly
    FLYE_ASM(
        DOWNSAMPLE.out.downsampled_fq
        .join(ESTIMATE_GENOME_SIZE.out.gsize)
    )

    // Hifiasm assembly
    HIFIASM_ASM(
        DOWNSAMPLE.out.downsampled_fq
        .join(ESTIMATE_GENOME_SIZE.out.gsize)
    )

    // Wtdbg2 assembly
    WTDBG2_ASM(
        DOWNSAMPLE.out.downsampled_fq
        .join(ESTIMATE_GENOME_SIZE.out.gsize)
    )

    // Raven assembly
    RAVEN_ASM(
        DOWNSAMPLE.out.downsampled_fq
    )

    // Combine assemblies with Autocycler
    COMBINE_ASMS(
        HIFIASM_ASM.out.asm
        .join(FLYE_ASM.out.asm)
        .join(WTDBG2_ASM.out.asm)
        .join(RAVEN_ASM.out.asm)
    )

    // --> Plasmid recovery & polishing
    // Downsample PE reads if available
    DOWNSAMPLE_PE(
        ch_input.short_fqs
        .join(ESTIMATE_GENOME_SIZE.out.gsize)
        )
    
    // Trim PE reads with fastp
    TRIM_PE(DOWNSAMPLE_PE.out.short_fqs)

    // Separate hybrid and HiFi-only samples based on the presence of short reads
    ch_hybrid = DOWNSAMPLE.out.downsampled_fq
        .join(TRIM_PE.out.trimmed_short_fqs)
        .join(FLYE_ASM.out.asm)
        .join(FLYE_ASM.out.asm_info)
        .filter { tuple -> tuple[0].hybrid == true }
    
    ch_hifi =  DOWNSAMPLE.out.downsampled_fq
        .filter { tuple -> tuple[0].hybrid == false } 
    
    // print sample IDs for hybrid and HiFi-only samples
    ch_hybrid.view { tuple -> "Hybrid samples: ${tuple[0].id}" }
    ch_hifi.view { tuple -> "HiFi-only samples: ${tuple[0].id}" }

    // recover plasmids with plassembler
    PLASSEMBLER_ASM(ch_hybrid)

    // label contigs and align with minimap2
    LABEL_AND_ALIGN(
        COMBINE_ASMS.out.asm
        .join(PLASSEMBLER_ASM.out.asm)
    )

    // merge recovered plasmids
    MERGE_ASMS(LABEL_AND_ALIGN.out.overlaps)
    
    // polish with polypolish
    POLISH(
        MERGE_ASMS.out.merged_asm
        .join(ch_input.short_fqs)
    )
    // <-- end of plasmid recovery & polishing

    // reorient with dnaapler
    REORIENT(
        POLISH.out.polished_asm
        .mix(ch_hifi)
    ) 
    
    ASM_VISUALIZATION(
        HIFIASM_ASM.out.asm_graph
        .join(FLYE_ASM.out.asm_graph)
        .join(RAVEN_ASM.out.asm_graph)
        .join(WTDBG2_ASM.out.asm)
        .join(COMBINE_ASMS.out.asm_graph)
        .join(PLASSEMBLER_ASM.out.asm_graph)
        .join(REORIENT.out.reoriented_asm)
    )

    if ( params.annotation || params.amrfinder ) {
        ANNOTATION(
            REORIENT.out.reoriented_asm
            .join(ch_input.organism)
        )
    }

    if ( params.amrfinder ) {
            AMRFINDER(
                ANNOTATION.out.bakta
                .join(ch_input.organism)
            )
        }

    emit:
    versions = ch_versions // channel: [ path(versions.yml) ]
}
