$ErrorActionPreference = "Continue"

$CondaExe = "C:\Users\thash\Miniconda3\Scripts\conda.exe"
$EnvName = "mbpsrl"

Write-Host "Testing single seed run..."
Write-Host "This should take about 2-3 minutes"
Write-Host ""

$testLog = "test_seed_output.txt"

Write-Host "Running: python run_cartpole.py --with-reward True --seed 0 --num-episodes 15"
Write-Host ""

& $CondaExe run -n $EnvName python run_cartpole.py --with-reward True --seed 0 --num-episodes 15

Write-Host ""
Write-Host "Checking output files..."

$expectedFiles = @(
    "seeds_data\cartpole_log_with_oracle_seed0.txt",
    "seeds_data\cartpole_timestep_rewards_with_oracle_seed0.txt"
)

foreach ($file in $expectedFiles) {
    if (Test-Path $file) {
        $lines = (Get-Content $file).Count
        Write-Host "[SUCCESS] $file exists with $lines lines"
    } else {
        Write-Host "[FAIL] $file not found!"
    }
}
