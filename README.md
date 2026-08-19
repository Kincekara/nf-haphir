# Kincekara/nf-haphir

[![Nextflow](https://img.shields.io/badge/version-%E2%89%A525.10.4-green?style=flat&logo=nextflow&logoColor=white&color=%230DC09D&link=https%3A%2F%2Fnextflow.io)](https://www.nextflow.io/)
[![nf-core template version](https://img.shields.io/badge/nf--core_template-4.0.2-green?style=flat&logo=nfcore&logoColor=white&color=%2324B064&link=https%3A%2F%2Fnf-co.re)](https://github.com/nf-core/tools/releases/tag/4.0.2)
[![run with docker](<https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker>)](https://www.docker.com/)
[![run with singularity](<https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000>)](https://sylabs.io/docs/)
[![Launch on Seqera Platform](<https://img.shields.io/badge/Launch%20%F0%9F%9A%80-Seqera%20Platform-%234256e7>)](https://cloud.seqera.io/launch?pipeline=https://github.com/Kincekara/nf-haphir)

## Introduction

**nf-HAPHiR** is nextflow version of [HAPHiR](https://github.com/Kincekara/haphir) pipeline.

nf-HAPHiR performs high‑quality bacterial genome assembly using PacBio HiFi long reads and Illumina short reads, combining accuracy, robustness, and efficient cloud execution.

The workflow runs multiple long‑read assemblers in parallel (Flye, Hifiasm, Raven, and one of Wtdbg2, HiCanu, LJA) It tries to generates a unified, high‑confidence consensus assembly using [Autocycler](https://github.com/rrwick/Autocycler). If fails, automaticaly repeats Autocycler step with a different assembler combination. Small circular plasmids are recovered through a dedicated hybrid assembly step using [Plassembler](https://github.com/gbouras13/plassembler), ensuring both chromosomal and plasmid components are accurately reconstructed.

## Features

- **Multi-assembler consensus**: Runs 4 independent long-read assemblers and combines them using Autocycler for enhanced accuracy
- **HiFI only support**: Works with PacBio HiFi-only data or hybrid HiFi + Illumina data
- **Plasmid recovery**: Dedicated plasmid assembly and recovery using Plassembler
- **Flexible inputs**: Accepts PacBio BAM or FASTQ files, automatically converts as needed
- **Quality control**: Includes read trimming, genome size estimation, and coverage normalization
- **Polishing**: Short-read polishing with Polypolish 
- **Annotation**: Optional standardized annotation with Bakta
- **Antimicrobial resistance detection**: Optional AMR analysis with AmrFinderPlus
- **Cloud-ready**: Designed for scalable execution on cloud via Nextflow
- **Containerized**: All tools run in Docker containers for reproducibility

## Usage

> [!NOTE]
> If you are new to Nextflow and nf-core, please refer to [this page](https://nf-co.re/docs/get_started/environment_setup/overview) on how to set-up Nextflow. Make sure to [test your setup](https://nf-co.re/docs/get_started/run-your-first-pipeline) with `-profile test` before running the workflow on actual data.

First, prepare a samplesheet with your input data that looks as follows:

`samplesheet.csv`:

```csv
sample,long_fq,short_fq1,short_fq2,organism
sample1,/path/to/sample1_long.fastq.gz,/path/to/sample1_short_R1.fastq.gz,/path/to/sample1_short_R2.fastq.gz,Escherichia coli
```

Short reads are optional, but recommended for best results. If short reads are not provided, the pipeline will run only the long-read assembly step.
If organism name is provided, the pipeline will use it only for bakta outputs such as contig headers.

Now, you can run the pipeline using:

```bash
nextflow run Kincekara/nf-haphir \
   -profile docker \
   --input samplesheet.csv \
   [ --outdir <OUTDIR> ] \
   [ --annotation false ]
   [ --amrfinder false ]
   [ --preset 1 ]
```

> [!NOTE]
> nf-HAPHiR runs Flye, Hifiasm, and Raven assemblers in parallel by default. The fourth assembler can be selected from Wtdbg2, HiCanu, or LJA based on the `preset` input. The presets define the order in which the long-read assemblers are run, allowing users to prioritize specific assemblers based on their preferences or prior experience. In case of failure in generating a consensus assembly, the workflow will automatically retry with a different assembler combination based on the selected preset. The presets are defined as follows:
>
> - preset 1 : Wtdbg2, Canu, LJA
> - preset 2 : Canu, LJA, Wtdbg2
> - preset 3 : LJA, Wtdbg2, Canu

## Credits

Kincekara/nf-haphir was originally written by Kutluhan Incekara.

## Contributions and Support

If you would like to contribute to this pipeline, please see the [contributing guidelines](docs/CONTRIBUTING.md).

## Citations

<!-- TODO nf-core: Add citation for pipeline after first release. Uncomment lines below and update Zenodo doi and badge at the top of this file. -->

<!-- If you use Kincekara/nf-haphir for your analysis, please cite it using the following doi: [10.5281/zenodo.XXXXXX](https://doi.org/10.5281/zenodo.XXXXXX) -->

This pipeline uses code and infrastructure developed and maintained by the [nf-core](https://nf-co.re) community, reused here under the [MIT license](https://github.com/nf-core/tools/blob/main/LICENSE).

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).
