#!/bin/bash
# download_fastq.sh
# Downloads and compresses FASTQ files from SRA for Crits-Christoph et al. (2021)
# Usage: ./download_fastq.sh

set -euo pipefail  # Exit on error, undefined variables, pipe failures

# Configuration
DATA_DIR="data"
LOG_DIR="logs"
THREADS=8
MAX_PARALLEL_DOWNLOADS=3  # Don't overwhelm NCBI servers

# Crits-Christoph et al. (2021) accessions
# 18 raw sewage samples from SF Bay Area wastewater treatment facilities
ACCESSIONS=(SRR12596165 SRR12596166)



# Setup directories
mkdir -p "$DATA_DIR" "$LOG_DIR"

# Color output for readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if parallel-fastq-dump is installed
check_dependencies() {
    log_info "Checking dependencies..."
    
    if ! command -v parallel-fastq-dump &> /dev/null; then
        log_error "parallel-fastq-dump not found"
        echo "Install with: pip install parallel-fastq-dump"
        exit 1
    fi
    
    if ! command -v pigz &> /dev/null; then
        log_warn "pigz not found, falling back to gzip (slower)"
        GZIP_CMD="gzip"
    else
        GZIP_CMD="pigz -p $THREADS"
    fi
    
    log_info "Dependencies OK"
}

# Download and compress a single accession
download_accession() {
    local acc=$1
    local r1="${DATA_DIR}/${acc}_1.fastq.gz"
    local r2="${DATA_DIR}/${acc}_2.fastq.gz"
    local log_file="${LOG_DIR}/${acc}.log"
    
    # Check if already downloaded
    if [ -f "$r1" ] && [ -f "$r2" ]; then
        log_info "SKIP: $acc (already exists)"
        return 0
    fi
    
    log_info "Downloading: $acc"
    
    # Download with parallel-fastq-dump
    if parallel-fastq-dump \
        --sra-id "$acc" \
        --threads "$THREADS" \
        --outdir "$DATA_DIR" \
        --split-files \
        --gzip \
        --tmpdir /tmp \
        > "$log_file" 2>&1; then
        
        log_info "SUCCESS: $acc"
        
        # Verify both files were created
        if [ ! -f "$r1" ] || [ ! -f "$r2" ]; then
            log_error "FAIL: $acc (missing R1 or R2)"
            return 1
        fi
        
        # Clean up any uncompressed files that might exist
        rm -f "${DATA_DIR}/${acc}_1.fastq" "${DATA_DIR}/${acc}_2.fastq"
        
        return 0
    else
        log_error "FAIL: $acc (check logs/$acc.log)"
        return 1
    fi
}

# Main execution
main() {
    log_info "Starting FASTQ download pipeline"
    log_info "Target: ${#ACCESSIONS[@]} accessions"
    log_info "Threads per download: $THREADS"
    log_info "Max parallel downloads: $MAX_PARALLEL_DOWNLOADS"
    echo
    
    check_dependencies
    echo
    
    # Track success/failure
    local success_count=0
    local skip_count=0
    local fail_count=0
    
    # Export function and variables for GNU parallel
    export -f download_accession log_info log_warn log_error
    export DATA_DIR LOG_DIR THREADS GZIP_CMD GREEN YELLOW RED NC
    
    # Use GNU parallel if available, otherwise sequential
    if command -v parallel &> /dev/null; then
        log_info "Using GNU parallel for concurrent downloads"
        printf '%s\n' "${ACCESSIONS[@]}" | \
            parallel -j "$MAX_PARALLEL_DOWNLOADS" --bar \
            download_accession {}
    else
        log_warn "GNU parallel not found, downloading sequentially"
        for acc in "${ACCESSIONS[@]}"; do
            download_accession "$acc"
        done
    fi
    
    # Generate summary
    echo
    log_info "=== Download Summary ==="
    for acc in "${ACCESSIONS[@]}"; do
        r1="${DATA_DIR}/${acc}_1.fastq.gz"
        r2="${DATA_DIR}/${acc}_2.fastq.gz"
        
        if [ -f "$r1" ] && [ -f "$r2" ]; then
            ((success_count++))
        else
            ((fail_count++))
            log_error "Missing: $acc"
        fi
    done
    
    echo
    log_info "Total accessions: ${#ACCESSIONS[@]}"
    log_info "Successfully downloaded: $success_count"
    log_info "Failed: $fail_count"
    
    if [ $fail_count -gt 0 ]; then
        echo
        log_warn "Some downloads failed. Check logs/ directory for details"
        log_warn "Re-run this script to retry failed downloads"
        exit 1
    fi
    
    echo
    log_info "All downloads complete!"
}

# Run main function
main "$@"