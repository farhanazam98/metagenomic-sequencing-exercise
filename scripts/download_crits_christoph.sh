#!/bin/bash

set -euo pipefail

ACCESSIONS=(
    SRR12596165 SRR12596166 SRR12596167 SRR12596168
    SRR12596169 SRR12596170 SRR12596171 SRR12596172
    SRR12596173 SRR12596174 SRR12596175 SRR23998353
    SRR23998354 SRR23998355 SRR23998356 SRR23998357
)

for acc in "${ACCESSIONS[@]}"; do
    if [ -f "data/${acc}_1.fastq.gz" ] && [ -f "data/${acc}_2.fastq.gz" ]; then
        echo "[SKIP] $acc already downloaded"
        continue
    fi
    
    echo "[DOWNLOAD] $acc"
    parallel-fastq-dump \
        --sra-id "$acc" \
        --threads 8 \
        --outdir data/ \
        --split-files \
        --gzip \
        --tmpdir /tmp
done