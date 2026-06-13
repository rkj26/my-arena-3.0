#!/bin/bash
set -e

# =============================================================================
# Usage:
#   bash <(curl -s https://raw.githubusercontent.com/rkj26/my-arena-3.0/main/install.sh)
#   OR if already cloned:
#   bash my-arena-3.0/install.sh --platform vastai
#
# Options:
#   --platform [runpod|vastai]  (Default: runpod)
#   --no-llm-context            Skip cloning arena-llm-context
# =============================================================================

# Defaults
PLATFORM="runpod"
CONDA_ENV="arena-env"
PYTHON_VERSION="3.11"
CLONE_LLM_CONTEXT=true
PRIMARY_REPO_URL="https://github.com/rkj26/my-arena-3.0.git"
PRIMARY_REPO_DIR="my-arena-3.0"

# Parse args
while [[ $# -gt 0 ]]; do
    case $1 in
        --platform)
            PLATFORM="$2"
            shift 2
            ;;
        --no-llm-context) CLONE_LLM_CONTEXT=false; shift ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

echo "=== Setup: platform=$PLATFORM, clone_llm_context=$CLONE_LLM_CONTEXT ==="

# --- Install Git & System Packages First ---
echo "=== Installing system packages ==="
if [[ "$PLATFORM" == "runpod" ]]; then
    apt update && apt install -y git curl wget
elif [[ "$PLATFORM" == "vastai" ]]; then
    sudo apt update && sudo apt install -y git curl wget
fi

# --- Ensure Primary Repo Exists ---
# If we aren't already inside the repo directory, and it doesn't exist, clone it.
if [[ "$(basename "$PWD")" != "$PRIMARY_REPO_DIR" ]]; then
    if [ ! -d "$PRIMARY_REPO_DIR" ]; then
        echo "=== Cloning primary repo: $PRIMARY_REPO_DIR ==="
        git clone "$PRIMARY_REPO_URL"
    fi
    cd "$PRIMARY_REPO_DIR"
    WAS_OUTSIDE=true
else
    WAS_OUTSIDE=false
fi

# --- Install Miniconda ---
echo "=== Installing Miniconda ==="
mkdir -p ~/miniconda3
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda3/miniconda.sh
bash ~/miniconda3/miniconda.sh -b -u -p ~/miniconda3
rm -rf ~/miniconda3/miniconda.sh

# Source conda.sh to get conda activate working in this script
source ~/miniconda3/etc/profile.d/conda.sh
~/miniconda3/bin/conda init bash

# --- Accept conda TOS ---
echo "=== Accepting Conda TOS ==="
conda tos accept --