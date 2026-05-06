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
    outdir

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
            storeDir: "${outdir}/pipeline_info",
            name: 'nf-haphir_software_' + 'versions.yml',
            sort: true,
            newLine: true,
        )

    // Genome size estimation
    ESTIMATE_GENOME_SIZE(ch_samplesheet)

    // // Downsampling
    // DOWNSAMPLE(ch_samplesheet)

    // // Flye assembly
    // FLYE_ASM(ch_samplesheet)

    // // Hifiasm assembly
    // HIFIASM_ASM(ch_samplesheet)

    // // wtdbg2 assembly
    // WTDBG2_ASM(ch_samplesheet)

    // // Raven assembly
    // RAVEN_ASM(ch_samplesheet)

    // // Combine assemblies with Autocycler
    // COMBINE_ASMS(ch_samplesheet)

    // // Plasmid recovery & polishing
    // // if PE data is available, use trimmed PE reads for plasmid recovery with Plassembler, otherwise use untrimmed long reads
    // if (ch_samplesheet.filter { it.short_fq1 != null && it.short_fq2 != null }.count() > 0) {
    //     DOWNSAMPLE_PE(ch_samplesheet)
    //     TRIM_PE(ch_samplesheet)
    //     PLASSEMBLER_ASM(ch_samplesheet)
    //     LABEL_AND_ALIGN(ch_samplesheet)
    //     MERGE_ASMS(ch_samplesheet)
    //     POLISH(ch_samplesheet)
    // }

    // REORIENT(ch_samplesheet)
    
    // ASM_VISUALIZATION(ch_samplesheet)

    // if (params.annotation || params.amrfinder) {
    //     ANNOTATION(ch_samplesheet)
    // }

    // if (params.amrfinder) {
    //         AMRFINDER(ch_samplesheet)
    //     }

    emit:
    versions = ch_versions // channel: [ path(versions.yml) ]
}
