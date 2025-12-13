#!/bin/bash

# Create output directory
mkdir -p data/raw/fastq

# Read SRR list and download each sample
while read srr; do
  echo "Downloading ${srr}..."
  
  # Download and split into R1 and R2 files
  fasterq-dump --split-files ${srr} --outdir data/raw/fastq
  
  # Compress to save space
  gzip data/raw/fastq/${srr}_*.fastq
  
  echo "Completed ${srr}"
done < data/srr_acc_list.txt

echo "All downloads complete!"
EOF