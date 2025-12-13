#!/bin/bash
# cleanup_workspace.sh
# Utility to clean up intermediate files and validate final state
# Usage: ./cleanup_workspace.sh [--dry-run]

set -euo pipefail

DATA_DIR="data"
DRY_RUN=false

# Parse arguments
if [ "${1:-}" = "--dry-run" ]; then
    DRY_RUN=true
    echo "DRY RUN MODE - No files will be deleted"
    echo
fi

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=== Workspace Cleanup Utility ==="
echo

# Find and report uncompressed FASTQ files
echo "Checking for uncompressed FASTQ files..."
uncompressed_files=$(find "$DATA_DIR" -name "*.fastq" 2>/dev/null || true)

if [ -z "$uncompressed_files" ]; then
    echo -e "${GREEN}✓ No uncompressed files found${NC}"
else
    echo -e "${YELLOW}Found uncompressed files:${NC}"
    echo "$uncompressed_files"
    echo
    
    # Check if corresponding .gz exists
    while IFS= read -r file; do
        gz_file="${file}.gz"
        if [ -f "$gz_file" ]; then
            echo -e "${YELLOW}→ Removing redundant: $(basename "$file")${NC}"
            if [ "$DRY_RUN" = false ]; then
                rm "$file"
            fi
        else
            echo -e "${RED}⚠ Warning: $file exists but $gz_file does not${NC}"
        fi
    done <<< "$uncompressed_files"
fi

echo
echo "=== Validation Report ==="

# Expected files
expected_accessions=(
    SRR12596165 SRR12596166 SRR12596167 SRR12596168
    SRR12596169 SRR12596170 SRR12596171 SRR12596172
    SRR12596173 SRR12596174 SRR12596175 SRR23998353
    SRR23998354 SRR23998355 SRR23998356 SRR23998357
)

missing_count=0
present_count=0

for acc in "${expected_accessions[@]}"; do
    r1="${DATA_DIR}/${acc}_1.fastq.gz"
    r2="${DATA_DIR}/${acc}_2.fastq.gz"
    
    if [ -f "$r1" ] && [ -f "$r2" ]; then
        ((present_count++))
        # Check file sizes
        size_r1=$(stat -f%z "$r1" 2>/dev/null || stat -c%s "$r1" 2>/dev/null)
        size_r2=$(stat -f%z "$r2" 2>/dev/null || stat -c%s "$r2" 2>/dev/null)
        
        if [ "$size_r1" -lt 1000 ] || [ "$size_r2" -lt 1000 ]; then
            echo -e "${RED}✗ $acc: Suspiciously small files (<1KB)${NC}"
        fi
    else
        echo -e "${RED}✗ Missing: $acc${NC}"
        [ ! -f "$r1" ] && echo "  - Missing R1"
        [ ! -f "$r2" ] && echo "  - Missing R2"
        ((missing_count++))
    fi
done

echo
echo "Total accessions: ${#expected_accessions[@]}"
echo -e "${GREEN}Present: $present_count${NC}"
if [ $missing_count -gt 0 ]; then
    echo -e "${RED}Missing: $missing_count${NC}"
fi

# Disk usage summary
echo
echo "=== Disk Usage ==="
du -sh "$DATA_DIR" 2>/dev/null || echo "Data directory not found"

# Count total files
total_gz=$(find "$DATA_DIR" -name "*.fastq.gz" | wc -l | tr -d ' ')
echo "Total .fastq.gz files: $total_gz (expected: 36)"

if [ "$DRY_RUN" = true ]; then
    echo
    echo "To actually perform cleanup, run without --dry-run flag"
fi