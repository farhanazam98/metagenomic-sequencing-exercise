# SRA Download Toolkit for Metagenomic Studies

A practical guide and scripts for downloading metagenomic sequencing data from NCBI's Sequence Read Archive (SRA). Developed while reproducing the [Crits-Christoph et al. wastewater surveillance analysis](https://data.securebio.org/wills-public-notebook/notebooks/2024-10-17_crits-christoph-2-4-0.html).

## Motivation

Metagenomic sequencing relies on downloading large SRA files for analysis. However, downloading this data presents practical barriers:
- Manual download of large files is time-consuming and error-prone
- Cloud deployment requires understanding SRA toolkit configuration
- Reproducibility requires careful dependency management

This toolkit provides working scripts and documentation for setting up an efficient SRA download workflow, particularly useful for researchers validating or extending published metagenomic analyses.

## What This Provides

### 1. SRA Download Scripts
- **Batch downloading** from sample accession lists
- **Error handling** with failed sample tracking and continuation from interruptions
- **Progress monitoring** for download + fastq conversion

### 2. AWS EC2 Setup Guide
- EC2 instance configuration for SRA downloads
- Documentation on SRA toolkit setup in EC2 instance

## Quick Start

See [workflow.ipynb](workflow.ipynb) for detailed setup instructions

## Technical Notes

## Related Work

This toolkit enables replication of analyses like:
- [Crits-Christoph et al. wastewater surveillance](https://data.securebio.org/wills-public-notebook/notebooks/2024-10-17_crits-christoph-2-4-0.html)

## Limitations

- Focuses on download/preprocessing; viral detection is separate
- Sequential downloads (no parallelization currently implemented)
- Assumes standard SRA toolkit installation