# metagenomic-sequencing-exercise
Obtain the high-level composition of the samples in the [Crits-Christoph et al. (2021)](https://journals.asm.org/doi/10.1128/mbio.02703-20) study, which includes 18 raw sewage samples collected from wastewater treatment facilities in the San Francisco Bay Area. I am essentially reproducing the results from [Will’s notebook](https://data.securebio.org/wills-public-notebook/notebooks/2024-02-04_crits-christoph-1.html). 

## Key Concepts

**SRA**: NCBI's public repository for DNA sequencing data. It can be thought of as "GitHub for genomic reads"
**R1/R2 Reads**: For each DNA fragment, there are two FASTQ files, one of which stores a "forward read" (R1) and another which stores a "reverse read" (R2). Both of these are required for metagenomic sequencing. Here's a [short article](https://www.khanacademy.org/science/ap-biology/gene-expression-and-regulation/replication/a/hs-dna-structure-and-replication-review) that explains how DNA is structured.. 
