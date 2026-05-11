#!/bin/bash
set -e

# =============================================================================
# Usage:
#   1. Place this file in the directory containing 'my-arena-3.0'
#   2. Run: bash install_mac.sh
# =============================================================================

# Config
PRIMARY_REPO_DIR="my-arena-3.0"
CONDA_ENV="arena-env"
PYTHON_VERSION="3.11"
CLONE_LLM_CONTEXT=true

echo "=== Starting ARENA 3.0 Setup for macOS ==="

# --- 1. Smart Conda Check & Install ---
if ! command -v conda &> /dev/null; then
    echo "=== Conda not found. Installing Miniconda for Mac... ==="
    
    # Detect Architecture (M1/M2/M3 vs Intel)
    ARCH=$(uname -m)
    if [ "$ARCH" = "arm64" ]; then
        MINICONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-arm64.sh"
    else
        MINICONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-x86_64.sh"
    fi

    echo "Downloading Miniconda for $ARCH..."
    curl -L $MINICONDA_URL -o ~/miniconda.sh
    bash ~/miniconda.sh -b -p $HOME/miniconda3
    rm ~/miniconda.sh
    
    # Initialize Conda for this script session
    source "$HOME/miniconda3/etc/profile.d/conda.sh"
    # Initialize for future terminal sessions
    $HOME/miniconda3/bin/conda init zsh
    echo "=== Miniconda installed successfully! ==="
else
    echo "=== Found existing Conda installation. Skipping install. ==="
    # Ensure conda functions are available in this script
    CONDA_PATH=$(conda info --base)
    source "$CONDA_PATH/etc/profile.d/conda.sh"
fi

# --- 2. Create and Activate Env ---
echo "=== Setting up Conda environment: $CONDA_ENV ==="
conda create -n "$CONDA_ENV" python="$PYTHON_VERSION" -y

# Hook into the shell to allow 'conda activate' inside the script
eval "$(conda shell.bash hook)"
conda activate "$CONDA_ENV"

# --- 3. System Dependencies (Homebrew) ---
if command -v brew &> /dev/null; then
    echo "=== Checking system packages via Homebrew ==="
    for pkg in git curl; do
        if ! command -v $pkg &> /dev/null; then
            brew install $pkg
        fi
    done
fi

# --- 4. Repo Setup ---
if $CLONE_LLM_CONTEXT; then
    if [ ! -d "arena-llm-context" ]; then
        echo "=== Cloning arena-llm-context ==="
        git clone -b main "https://github.com/callummcdougall/arena-llm-context.git"
    fi
fi

# --- 5. Python Dependencies ---
if [ -d "$PRIMARY_REPO_DIR" ]; then
    echo "=== Installing dependencies into $CONDA_ENV ==="
    cd "$PRIMARY_REPO_DIR"
    pip install -U pip setuptools wheel
    pip install -r requirements.txt
    conda install -n "$CONDA_ENV" ipykernel --update-deps --force-reinstall -y
    cd ..
else
    echo "Error: Directory '$PRIMARY_REPO_DIR' not found!"
    exit 1
fi

# --- 6. VS Code Configuration ---
echo "=== Configuring VS Code workspace settings ==="
ENV_PYTHON_PATH="$(conda info --base)/envs/$CONDA_ENV/bin/python"

mkdir -p ".vscode"
cat > ".vscode/settings.json" << EOF
{
    "python.defaultInterpreterPath": "$ENV_PYTHON_PATH",
    "python.analysis.extraPaths": [
        "./$PRIMARY_REPO_DIR/chapter0_fundamentals/exercises",
        "./$PRIMARY_REPO_DIR/chapter1_transformer_interp/exercises",
        "./$PRIMARY_REPO_DIR/chapter2_rl/exercises",
        "./$PRIMARY_REPO_DIR/chapter3_llm_evals/exercises",
        "./$PRIMARY_REPO_DIR/chapter4_alignment_science/exercises"
    ]
}
EOF

echo "=== Setup Complete! ==="
echo "To start, run: conda activate $CONDA_ENV"