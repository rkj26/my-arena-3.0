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
conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main
conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r

# --- Create and activate conda env ---
echo "=== Creating conda env '$CONDA_ENV' (python $PYTHON_VERSION) ==="
conda create -n "$CONDA_ENV" python="$PYTHON_VERSION" -y
conda activate "$CONDA_ENV"
echo "=== Active Python: $(which python) ==="

# --- Install Python deps ---
echo "=== Installing Python dependencies ==="
pip install -U pip setuptools wheel
if [ -f "requirements.txt" ]; then
    pip install -r requirements.txt
else
    echo "Warning: requirements.txt not found!"
fi
conda install -n "$CONDA_ENV" ipykernel --update-deps --force-reinstall -y

# --- Register Conda environment with JupyterLab ---
echo "=== Registering Conda environment with JupyterLab ==="
python -m ipykernel install --user --name="$CONDA_ENV" --display-name="Python (arena-env)"

# Move back to the parent directory if we stepped into the repo earlier
if [ "$WAS_OUTSIDE" = true ]; then
    cd ..
fi

# --- Optional Extra Context Repo ---
if $CLONE_LLM_CONTEXT; then
    REPO="callummcdougall/arena-llm-context"
    BRANCH="main"
    if [ ! -d "arena-llm-context" ]; then
        echo "=== Cloning $REPO (branch: $BRANCH) ==="
        git clone -b "$BRANCH" "https://github.com/${REPO}.git"
    else
        echo "=== $REPO already cloned ==="
    fi
fi

# --- VS Code workspace settings ---
echo "=== Configuring VS Code workspace settings ==="
HOME_DIR="$HOME"
mkdir -p "$HOME_DIR/.vscode"
cat > "$HOME_DIR/.vscode/settings.json" << EOF
{
    "python.defaultInterpreterPath": "$HOME_DIR/miniconda3/envs/$CONDA_ENV/bin/python",
    "python.analysis.extraPaths": [
        "$HOME_DIR/$PRIMARY_REPO_DIR/chapter0_fundamentals/exercises",
        "$HOME_DIR/$PRIMARY_REPO_DIR/chapter1_transformer_interp/exercises",
        "$HOME_DIR/$PRIMARY_REPO_DIR/chapter2_rl/exercises",
        "$HOME_DIR/$PRIMARY_REPO_DIR/chapter3_llm_evals/exercises",
        "$HOME_DIR/$PRIMARY_REPO_DIR/chapter4_alignment_science/exercises"
    ]
}
EOF

echo "=== Setup Done! ==="