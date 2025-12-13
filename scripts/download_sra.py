#!/usr/bin/env python3
from pathlib import Path
import pandas as pd
import subprocess
import shutil

COMPRESSOR = "pigz" if shutil.which("pigz") else "gzip"


def ensure_compressed(srr_id, output_dir):
    output_dir = Path(output_dir)

    if list(output_dir.glob(f"{srr_id}*.fastq.gz")):
        return True

    fastq_files = list(output_dir.glob(f"{srr_id}*.fastq"))
    if not fastq_files:
        return False

    for fastq in fastq_files:
        print(f"    Compressing {fastq} using {COMPRESSOR}", flush=True)

        cmd = [COMPRESSOR, "-f"]
        if COMPRESSOR == "pigz":
            cmd += ["-p", "4"]
        cmd.append(str(fastq))

        subprocess.run(cmd, check=True)

    return True


def check_downloaded(srr_id, output_dir):
    """Check if SRR files already exist"""
    if ensure_compressed(srr_id, output_dir):
        print(f"✓ {srr_id} - Ready (already present)")
        return True
    return False

def download_srr(srr_id, output_dir):
    """Download SRR if not already present"""
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    
    # Check if already exists
    if check_downloaded(srr_id, output_dir):
        return True
    
    print(f"Downloading {srr_id}...")
    
    try:
        # Download with fasterq-dump
        cmd = [
            "fasterq-dump",
            "--split-files",
            "--outdir", str(output_dir),
            "--progress",
            srr_id
        ]
        subprocess.run(cmd, check=True)        

        # Compress the files
        for fastq in output_dir.glob(f"{srr_id}*.fastq"):
           subprocess.run(
            ["gzip", "-v", str(fastq)],
            check=True,
            stdout=None,
            stderr=None
        )

        print(f"✓ {srr_id} - Download complete")
        return True
        
    except subprocess.CalledProcessError as e:
        print(f"✗ {srr_id} - Download failed: {e.stderr}")
        return False

if __name__ == "__main__":
    # Load SRR list
    srr_list = pd.read_csv("data/srr_acc_list.txt", header=None, names=["srr_id"])
    
    # Download each
    downloaded = 0
    failed = []
    
    for srr_id in srr_list["srr_id"]:
        if download_srr(srr_id, "data/raw/fastq/"):
            downloaded += 1
        else:
            failed.append(srr_id)
    
    # Summary
    print(f"\n{'='*50}")
    print(f"Successfully downloaded: {downloaded}")
    print(f"Failed: {len(failed)}")
    if failed:
        print(f"Failed IDs: {failed}")