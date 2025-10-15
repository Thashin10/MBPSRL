$ErrorActionPreference = "Continue"

$CondaExe = "C:\Users\thash\Miniconda3\Scripts\conda.exe"

Write-Host "Running CartPole WITH Oracle, Seed 99 (test run)"
Write-Host "This should take ~15 minutes for 15 episodes"
Write-Host ""

& $CondaExe run -n mbpsrl python run_cartpole.py --with-reward True --seed 99 --num-episodes 15

Write-Host ""
Write-Host "Test run completed. Checking output..."

if (Test-Path "seeds_data\cartpole_log_with_oracle_seed99.txt") {
    $lines = (Get-Content "seeds_data\cartpole_log_with_oracle_seed99.txt").Count
    Write-Host "Log file has $lines lines (should be 15)"
}

if (Test-Path "seeds_data\cartpole_timestep_rewards_with_oracle_seed99.txt") {
    $lines = (Get-Content "seeds_data\cartpole_timestep_rewards_with_oracle_seed99.txt").Count
    Write-Host "Timestep file has $lines lines (should be ~3000)"
}
