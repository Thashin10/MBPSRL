# PETS Pendulum - Remaining seeds (2, 3, 4)
# Seeds 0 and 1 already complete with 3000 timesteps each
$CondaExe = "C:\Users\thash\Miniconda3\Scripts\conda.exe"

Write-Host "============================================================"
Write-Host "PETS Pendulum - Remaining Seeds (2, 3, 4)"
Write-Host "============================================================"
Write-Host "Target: 3000 timesteps per seed (15 episodes)"
Write-Host "Parameters: 100 trajs, 15 horizon, 3 iters"
Write-Host "Seeds 0 and 1 already completed"
Write-Host "Expected time: ~25 minutes per seed, ~75 minutes total"
Write-Host "============================================================"
Write-Host ""

$startTime = Get-Date

for ($seed = 2; $seed -lt 5; $seed++) {
    $seedStart = Get-Date
    
    Write-Host "`n=========================================="
    Write-Host "Pendulum Seed $seed - Starting..."
    Write-Host "=========================================="
    
    & $CondaExe run -n mbpsrl python -u baselines/pets/run_pets_pendulum.py `
        --seed $seed `
        --num-episodes 15 `
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
Write-Host "All Pendulum experiments completed in $($totalDuration.ToString('0.0')) minutes"
Write-Host "============================================================"

Write-Host "`nVerifying all Pendulum files (seeds 0-4)..."
for ($seed = 0; $seed -lt 5; $seed++) {
    $logFile = "seeds_data\pets_pendulum_log_seed$seed.txt"
    $timestepFile = "seeds_data\pets_pendulum_timestep_rewards_seed$seed.txt"
    
    if (Test-Path $logFile) {
        $episodes = (Get-Content $logFile | Measure-Object -Line).Lines
        $timesteps = (Get-Content $timestepFile | Measure-Object -Line).Lines
        Write-Host "[OK] Seed $seed : $episodes episodes, $timesteps timesteps"
    } else {
        Write-Host "[MISSING] Seed $seed files"
    }
}
