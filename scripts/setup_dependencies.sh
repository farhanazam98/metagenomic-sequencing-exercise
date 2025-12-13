#!/bin/bash
# setup_dependencies.sh
# Installs all required dependencies for the metagenomic sequencing pipeline
# Usage: ./setup_dependencies.sh

set -euo pipefail

echo "=== Installing Dependencies ==="

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "Cannot detect OS. Exiting."
    exit 1
fi

# Install system dependencies
echo "Installing system packages..."
if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
    sudo apt-get update
    sudo apt-get install -y \
        wget \
        python3-pip \
        pigz \
        parallel \
        curl
elif [ "$OS" = "centos" ] || [ "$OS" = "rhel" ]; then
    sudo yum install -y \
        wget \
        python3-pip \
        pigz \
        parallel \
        curl
else
    echo "Unsupported OS: $OS"
    echo "Please install manually: wget, python3-pip, pigz, parallel"
    exit 1
fi

# Install parallel-fastq-dump
echo "Installing parallel-fastq-dump..."
pip3 install --user parallel-fastq-dump

# Install SRA Toolkit (if not already installed)
if ! command -v fasterq-dump &> /dev/null; then
    echo "Installing SRA Toolkit..."
    cd /tmp
    wget https://ftp-trace.ncbi.nlm.nih.gov/sra/sdk/current/sratoolkit.current-ubuntu64.tar.gz
    tar -xzf sratoolkit.current-ubuntu64.tar.gz
    
    # Move to /usr/local/bin or add to PATH
    TOOLKIT_DIR=$(ls -d sratoolkit.* | head -n1)
    echo "SRA Toolkit installed to: /tmp/$TOOLKIT_DIR"
    echo "Add to PATH: export PATH=/tmp/$TOOLKIT_DIR/bin:\$PATH"
    echo "Or run: sudo mv /tmp/$TOOLKIT_DIR /opt/ && sudo ln -s /opt/$TOOLKIT_DIR/bin/* /usr/local/bin/"
fi

# Verify installations
echo ""
echo "=== Verification ==="
command -v parallel-fastq-dump && echo "✓ parallel-fastq-dump installed" || echo "✗ parallel-fastq-dump missing"
command -v pigz && echo "✓ pigz installed" || echo "✗ pigz missing"
command -v parallel && echo "✓ GNU parallel installed" || echo "✗ parallel missing"
command -v fasterq-dump && echo "✓ SRA Toolkit installed" || echo "✗ SRA Toolkit missing"

echo ""
echo "=== Setup Complete ==="
echo "Run: ./download_fastq.sh"