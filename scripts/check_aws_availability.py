#!/usr/bin/env python3
import subprocess
import pandas as pd
from pathlib import Path

def check_s3_availability(srr_id):
    """Check if SRR exists on AWS S3"""
    bucket = "sra-pub-run-odp"
    prefix = f"sra/{srr_id}/"
    
    cmd = [
        "aws", "s3", "ls",
        f"s3://{bucket}/{prefix}",
        "--no-sign-request"
    ]
    
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, 
                               timeout=10, check=True)
        files = [line.split()[-1] for line in result.stdout.strip().splitlines() if line]
        return True, files
    except (subprocess.CalledProcessError, subprocess.TimeoutExpired):
        return False, []

if __name__ == "__main__":
    ssr_id_path = Path("data/srr_acc_list.txt")
    if not ssr_id_path.exists():
        raise FileNotFoundError(f"{ssr_id_path} does not exist. Please create it with the list of SRR IDs.")
    srr_list = ssr_id_path.read_text().strip().splitlines()
    
    results = []
    for srr_id in srr_list:
        available, files = check_s3_availability(srr_id)
        results.append({
            'srr_id': srr_id,
            'aws_available': available,
            'files': ', '.join(files) if files else 'N/A'
        })
        print(f"{srr_id}: {'✓' if available else '✗'}")
