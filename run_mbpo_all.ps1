# Run MBPO experiments for all seeds
# CartPole and Pendulum - 5 seeds each
$CondaExe = "C:\Users\thash\Miniconda3\Scripts\conda.exe"

Write-Host "============================================================"
Write-Host "MBPO Experiments - All Seeds"
Write-Host "============================================================"
Write-Host "Running: 2 environments × 5 seeds = 10 experiments"
Write-Host "Episodes: 15 per seed (targeting ~3000 timesteps)"
Write-Host "Expected time: ~10-15 minutes per seed, ~2-3 hours total"
Write-Host "============================================================"
Write-Host ""

$startTime = Get-Date

# ==================== CARTPOLE ====================
Write-Host "`n=========================================="
Write-Host "CARTPOLE EXPERIMENTS"
Write-Host "=========================================="

for ($seed = 0; $seed -lt 5; $seed++) {
    $seedStart = Get-Date
    
    Write-Host "`nCartPole Seed $seed - Starting..."
    
    & $CondaExe run -n mbpsrl python baselines/mbpo/run_mbpo_cartpole.py `
        --seed $seed `
        --num-episodes 15 `
        --max-steps 200
    
    $seedEnd = Get-Date
    $seedDuration = ($seedEnd - $seedStart).TotalMinutes
    Write-Host "Seed $seed completed in $($seedDuration.ToString('0.0')) minutes"
}

# ==================== PENDULUM ====================
Write-Host "`n=========================================="
Write-Host "PENDULUM EXPERIMENTS"
Write-Host "=========================================="

for ($seed = 0; $seed -lt 5; $seed++) {
    $seedStart = Get-Date
    
    Write-Host "`nPendulum Seed $seed - Starting..."
    
    & $CondaExe run -n mbpsrl python baselines/mbpo/run_mbpo_pendulum.py `
        --seed $seed `
        --num-episodes 15 `
        --max-steps 200
    
    $seedEnd = Get-Date
    $seedDuration = ($seedEnd - $seedStart).TotalMinutes
    Write-Host "Seed $seed completed in $($seedDuration.ToString('0.0')) minutes"
}

$endTime = Get-Date
$totalDuration = ($endTime - $startTime).TotalMinutes

Write-Host "`n============================================================"
Write-Host "All MBPO experiments completed in $($totalDuration.ToString('0.0')) minutes"
Write-Host "============================================================"

# Verify output files
Write-Host "`nVerifying output files..."
for ($seed = 0; $seed -lt 5; $seed++) {
    # CartPole
    $cartpoleLog = "seeds_data\mbpo_cartpole_log_seed$seed.txt"
    $cartpoleTimestep = "seeds_data\mbpo_cartpole_timestep_rewards_seed$seed.txt"
    
    if (Test-Path $cartpoleLog) {
        $episodes = (Get-Content $cartpoleLog | Measure-Object -Line).Lines
        $timesteps = (Get-Content $cartpoleTimestep | Measure-Object -Line).Lines
        Write-Host "[OK] CartPole Seed $seed : $episodes episodes, $timesteps timesteps"
    } else {
        Write-Host "[MISSING] CartPole Seed $seed files not found"
    }
    
    # Pendulum
    $pendulumLog = "seeds_data\mbpo_pendulum_log_seed$seed.txt"
    $pendulumTimestep = "seeds_data\mbpo_pendulum_timestep_rewards_seed$seed.txt"
    
    if (Test-Path $pendulumLog) {
        $episodes = (Get-Content $pendulumLog | Measure-Object -Line).Lines
        $timesteps = (Get-Content $pendulumTimestep | Measure-Object -Line).Lines
        Write-Host "[OK] Pendulum Seed $seed : $episodes episodes, $timesteps timesteps"
    } else {
        Write-Host "[MISSING] Pendulum Seed $seed files not found"
    }
}

Write-Host "`n============================================================"
Write-Host "MBPO experiments complete!"
Write-Host "Results saved in seeds_data/ directory"
Write-Host "============================================================"
