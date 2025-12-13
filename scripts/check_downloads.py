#!/usr/bin/env python3
from pathlib import Path
import pandas as pd

def check_downloaded(srr_id, output_dir):
    """Check if SRR files already exist"""
    output_dir = Path(output_dir)
    
    # Look for any files matching this SRR ID
    expected_files = list(output_dir.glob(f"{srr_id}*.fastq.gz"))
    
    if expected_files:
        print(f"✓ {srr_id} - Found {len(expected_files)} files")
        return True
    else:
        print(f"✗ {srr_id} - Not found")
        return False

if __name__ == "__main__":
    # Load SRR list
    srr_list = pd.read_csv("data/srr_acc_list.txt", header=None, names=["srr_id"])
    
    # Check each one
    downloaded = 0
    missing = 0
    
    for srr_id in srr_list["srr_id"]:
        if check_downloaded(srr_id, "data/raw/fastq/"):
            downloaded += 1
        else:
            missing += 1
    
    # Summary
    print(f"\n{'='*50}")
    print(f"Downloaded: {downloaded}")
    print(f"Missing: {missing}")
    print(f"Total: {len(srr_list)}")