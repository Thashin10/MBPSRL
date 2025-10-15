# PowerShell setup script for the mbpsrl project (Windows)
# Requires: conda (Anaconda/Miniconda) installed and on PATH

function Test-Conda {
	$conda = Get-Command conda -ErrorAction SilentlyContinue
	return $null -ne $conda
}

if (-not (Test-Conda)) {
	Write-Host "Conda was not found on PATH. Please install Anaconda or Miniconda and ensure 'conda' is available in your PowerShell session."
	Write-Host "https://docs.conda.io/projects/conda/en/latest/user-guide/install/index.html"
	exit 1
}

# Create conda env from environment.yml
conda env create -f environment.yml

# Activate environment
conda activate mbpsrl

# Install pip packages (from the cleaned pip requirements)
python -m pip install --upgrade pip
python -m pip install -r pip-requirements.txt

Write-Host "Environment 'mbpsrl' created (or already exists). Note: mujoco-py and MuJoCo require additional manual setup on Windows."
Write-Host "If you plan to run MuJoCo-based environments (Pusher/Reacher), consider using WSL2 or a Linux machine, or set up MuJoCo binaries and license file as described in mujoco-py docs."