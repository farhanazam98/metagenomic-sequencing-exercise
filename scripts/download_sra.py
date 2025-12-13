#!/usr/bin/env python3
from pathlib import Path
import pandas as pd
import subprocess
import shutil
from concurrent.futures import ThreadPoolExecutor, as_completed
from threading import Lock



COMPRESSOR = "pigz" if shutil.which("pigz") else "gzip"
print_lock = Lock()  # Prevent overlapping print statements


def thread_safe_print(*args, **kwargs):
    """Print with lock to avoid garbled output"""
    with print_lock:
        print(*args, **kwargs)


def compress_fastq_with_progress(fastq_path, threads=4):
    """
    Compress a FASTQ file using pigz (preferred) or gzip with a live progress bar using pv.
    Replaces the original FASTQ with a .fastq.gz file.
    """
    fastq_path = Path(fastq_path)
    gz_path = fastq_path.with_suffix(fastq_path.suffix + ".gz")

    if gz_path.exists():
        thread_safe_print(f"✓ {gz_path.name} already exists, skipping compression")
        return gz_path

    thread_safe_print(f"    Compressing {fastq_path.name}")

    if COMPRESSOR == "pigz":
        cmd = f"pv {fastq_path} | pigz -p {threads} > {gz_path}"
    else:
        cmd = f"pv {fastq_path} | gzip > {gz_path}"

    subprocess.run(cmd, shell=True, check=True)

    # Remove original FASTQ
    fastq_path.unlink()

    thread_safe_print(f"    ✓ {gz_path.name} compression complete")
    return gz_path


def ensure_compressed(srr_id, output_dir):
    output_dir = Path(output_dir)

    if list(output_dir.glob(f"{srr_id}*.fastq.gz")):
        return True

    fastq_files = list(output_dir.glob(f"{srr_id}*.fastq"))
    if not fastq_files:
        return False

    for fastq in fastq_files:
        compress_fastq_with_progress(fastq, threads=4)

    return True


def check_downloaded(srr_id, output_dir):
    """Check if SRR files already exist"""
    if ensure_compressed(srr_id, output_dir):
        thread_safe_print(f"✓ {srr_id} - Ready (already present)")
        return True
    return False

def download_srr(srr_id, output_dir):
    """Download SRR if not already present"""
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    
    # Check if already exists
    if check_downloaded(srr_id, output_dir):
        return True
    
    thread_safe_print(f"Downloading {srr_id}...")
    
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
        ensure_compressed(srr_id, output_dir)


        thread_safe_print(f"✓ {srr_id} - Download complete")
        return True
        
    except subprocess.CalledProcessError as e:
        thread_safe_print(f"✗ {srr_id} - Download failed: {e.stderr}")
        return False

if __name__ == "__main__":
    # Load SRR list
    srr_list = pd.read_csv("data/srr_acc_list.txt", header=None, names=["srr_id"])

    # Number of parallel downloads (adjust based on your instance)
    MAX_WORKERS = 2 # for t3.large

    
    # Download each
    downloaded = 0
    failed = []
    
    with ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
        # Submit all download jobs
        futures = {executor.submit(download_srr, srr_id, "data/raw/fastq/"): srr_id 
                   for srr_id in srr_list["srr_id"]}
        
        # Process as they complete
        for future in as_completed(futures):
            srr_id = futures[future]
            try:
                if future.result():
                    downloaded += 1
                else:
                    failed.append(srr_id)
            except Exception as e:
                thread_safe_print(f"✗ {srr_id} - Crashed: {e}")
                failed.append(srr_id)
    
    # Summary
    thread_safe_print(f"\n{'='*50}")
    thread_safe_print(f"Successfully downloaded: {downloaded}")
    thread_safe_print(f"Failed: {len(failed)}")
    if failed:
        thread_safe_print(f"Failed IDs: {failed}")