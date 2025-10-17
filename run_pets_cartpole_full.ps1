# Full PETS CartPole experiments - 5 seeds
# Need ~100 episodes per seed to reach 3000 timesteps
$CondaExe = "C:\Users\thash\Miniconda3\Scripts\conda.exe"

Write-Host "============================================================"
Write-Host "PETS CartPole - Full Experiments (5 seeds)"
Write-Host "============================================================"
Write-Host "Target: 3000 timesteps per seed (~100 episodes)"
Write-Host "Parameters: 100 trajs, 15 horizon, 3 iters"
Write-Host "Expected time: ~40-50 minutes per seed, ~3-4 hours total"
Write-Host "============================================================"
Write-Host ""

$startTime = Get-Date

for ($seed = 0; $seed -lt 5; $seed++) {
    $seedStart = Get-Date
    
    Write-Host "`n=========================================="
    Write-Host "CartPole Seed $seed - Starting..."
    Write-Host "=========================================="
    
    & $CondaExe run -n mbpsrl python -u baselines/pets/run_pets_cartpole.py `
        --seed $seed `
        --num-episodes 100 `
        --num-trajs 100 `
        --plan-hor 15 `
        --max-iters 3
    
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
    $logFile = "seeds_data\pets_cartpole_log_seed$seed.txt"
    $timestepFile = "seeds_data\pets_cartpole_timestep_rewards_seed$seed.txt"
    
    if (Test-Path $logFile) {
        $episodes = (Get-Content $logFile | Measure-Object -Line).Lines
        $timesteps = (Get-Content $timestepFile | Measure-Object -Line).Lines
        Write-Host "[OK] Seed $seed : $episodes episodes, $timesteps timesteps"
    } else {
        Write-Host "[MISSING] Seed $seed files"
    }
}
