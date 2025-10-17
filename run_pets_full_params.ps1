# PETS CartPole experiments with FULL PAPER PARAMETERS
# Specifications from paper: H_p=30, K=500, E=50, I=5, α=0.1, var=1.0
$CondaExe = "C:\Users\thash\Miniconda3\Scripts\conda.exe"

Write-Host "============================================================"
Write-Host "PETS CartPole - FULL PAPER PARAMETERS (5 seeds)"
Write-Host "============================================================"
Write-Host "Parameters:"
Write-Host "  Planning horizon (H_p): 30"
Write-Host "  Trajectories (K): 500"
Write-Host "  Elites (E): 50"
Write-Host "  CEM iterations (I): 5"
Write-Host "  Smoothing (alpha): 0.1"
Write-Host "  Initial variance: 1.0"
Write-Host "  Episodes: 15 (targeting 200 steps each = 3000 timesteps)"
Write-Host ""
Write-Host "Expected time: ~15-20 minutes per episode"
Write-Host "               ~4-5 hours per seed"
Write-Host "               ~20-25 hours total for 5 seeds"
Write-Host "============================================================"
Write-Host ""

$response = Read-Host "This will take ~20-25 hours. Continue? (yes/no)"
if ($response -ne "yes") {
    Write-Host "Cancelled."
    exit
}

$startTime = Get-Date

for ($seed = 0; $seed -lt 5; $seed++) {
    $seedStart = Get-Date
    
    Write-Host "`n=========================================="
    Write-Host "CartPole Seed $seed - Starting..."
    Write-Host "=========================================="
    
    & $CondaExe run -n mbpsrl python -u baselines/pets/run_pets_cartpole.py `
        --seed $seed `
        --num-episodes 15 `
        --num-trajs 500 `
        --num-elites 50 `
        --plan-hor 30 `
        --max-iters 5 `
        --alpha 0.1 `
        --var 1.0
    
    $seedEnd = Get-Date
    $seedDuration = ($seedEnd - $seedStart).TotalMinutes
    Write-Host "Seed $seed completed in $($seedDuration.ToString('0.0')) minutes"
}

$endTime = Get-Date
$totalDuration = ($endTime - $startTime).TotalMinutes

Write-Host "`n============================================================"
Write-Host "All CartPole experiments completed in $($totalDuration.ToString('0.0')) minutes"
Write-Host "============================================================"

Write-Host "`nVerifying output files..."
for ($seed = 0; $seed -lt 5; $seed++) {
    $logFile = "seeds_data\pets_full_cartpole_log_seed$seed.txt"
    $timestepFile = "seeds_data\pets_full_cartpole_timestep_rewards_seed$seed.txt"
    
    if (Test-Path $logFile) {
        $episodes = (Get-Content $logFile | Measure-Object -Line).Lines
        $timesteps = (Get-Content $timestepFile | Measure-Object -Line).Lines
        Write-Host "[OK] Seed $seed : $episodes episodes, $timesteps timesteps"
    } else {
        Write-Host "[MISSING] Seed $seed files not found"
    }
}
