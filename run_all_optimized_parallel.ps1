# Run all optimized baseline experiments in parallel
# 4 experiments × 5 seeds = 20 total runs
# Expected total time: 6-8 hours (running 4 experiments in parallel)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Starting All Optimized Baseline Experiments" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Experiments to run:" -ForegroundColor Yellow
Write-Host "  1. MBPO CartPole (5 seeds)" -ForegroundColor Green
Write-Host "  2. MBPO Pendulum (5 seeds)" -ForegroundColor Green
Write-Host "  3. PETS CartPole (5 seeds)" -ForegroundColor Green
Write-Host "  4. PETS Pendulum (5 seeds)" -ForegroundColor Green
Write-Host ""
Write-Host "Total: 20 runs in 4 parallel terminals" -ForegroundColor Yellow
Write-Host "Expected time: 6-8 hours" -ForegroundColor Yellow
Write-Host ""

# Activate conda environment
Write-Host "Activating conda environment 'mbpsrl'..." -ForegroundColor Cyan
conda activate mbpsrl

# Create output directory for organized results
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$outputDir = "optimized_results_$timestamp"
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
Write-Host "Results will be saved to: $outputDir" -ForegroundColor Green
Write-Host ""

# Terminal 1: MBPO CartPole (5 seeds)
Write-Host "[Terminal 1] Starting MBPO CartPole (5 seeds)..." -ForegroundColor Magenta
$mbpoCartPoleScript = @"
conda activate mbpsrl
cd '$PWD'
Write-Host '========================================' -ForegroundColor Cyan
Write-Host 'TERMINAL 1: MBPO CartPole (5 seeds)' -ForegroundColor Cyan
Write-Host '========================================' -ForegroundColor Cyan
Write-Host ''

cd baselines\mbpo

for (`$seed = 0; `$seed -lt 5; `$seed++) {
    Write-Host ''
    Write-Host '----------------------------------------' -ForegroundColor Yellow
    Write-Host "Running MBPO CartPole - Seed `$seed/4" -ForegroundColor Green
    Write-Host '----------------------------------------' -ForegroundColor Yellow
    `$startTime = Get-Date
    
    python run_mbpo_cartpole.py --seed `$seed --num-episodes 15 --output-dir ../../$outputDir
    
    `$elapsed = (Get-Date) - `$startTime
    Write-Host "Seed `$seed completed in: `$(`$elapsed.ToString('hh\:mm\:ss'))" -ForegroundColor Green
}

Write-Host ''
Write-Host '========================================' -ForegroundColor Green
Write-Host 'TERMINAL 1: MBPO CartPole - ALL SEEDS COMPLETE!' -ForegroundColor Green
Write-Host '========================================' -ForegroundColor Green
Read-Host 'Press Enter to close this terminal'
"@

Start-Process powershell -ArgumentList "-NoExit", "-Command", $mbpoCartPoleScript

# Terminal 2: MBPO Pendulum (5 seeds)
Write-Host "[Terminal 2] Starting MBPO Pendulum (5 seeds)..." -ForegroundColor Magenta
$mbpoPendulumScript = @"
conda activate mbpsrl
cd '$PWD'
Write-Host '========================================' -ForegroundColor Cyan
Write-Host 'TERMINAL 2: MBPO Pendulum (5 seeds)' -ForegroundColor Cyan
Write-Host '========================================' -ForegroundColor Cyan
Write-Host ''

cd baselines\mbpo

for (`$seed = 0; `$seed -lt 5; `$seed++) {
    Write-Host ''
    Write-Host '----------------------------------------' -ForegroundColor Yellow
    Write-Host "Running MBPO Pendulum - Seed `$seed/4" -ForegroundColor Green
    Write-Host '----------------------------------------' -ForegroundColor Yellow
    `$startTime = Get-Date
    
    python run_mbpo_pendulum.py --seed `$seed --num-episodes 15 --output-dir ../../$outputDir
    
    `$elapsed = (Get-Date) - `$startTime
    Write-Host "Seed `$seed completed in: `$(`$elapsed.ToString('hh\:mm\:ss'))" -ForegroundColor Green
}

Write-Host ''
Write-Host '========================================' -ForegroundColor Green
Write-Host 'TERMINAL 2: MBPO Pendulum - ALL SEEDS COMPLETE!' -ForegroundColor Green
Write-Host '========================================' -ForegroundColor Green
Read-Host 'Press Enter to close this terminal'
"@

Start-Process powershell -ArgumentList "-NoExit", "-Command", $mbpoPendulumScript

# Terminal 3: PETS CartPole (5 seeds)
Write-Host "[Terminal 3] Starting PETS CartPole (5 seeds)..." -ForegroundColor Magenta
$petsCartPoleScript = @"
conda activate mbpsrl
cd '$PWD'
Write-Host '========================================' -ForegroundColor Cyan
Write-Host 'TERMINAL 3: PETS CartPole (5 seeds)' -ForegroundColor Cyan
Write-Host '========================================' -ForegroundColor Cyan
Write-Host ''

cd baselines\pets

for (`$seed = 0; `$seed -lt 5; `$seed++) {
    Write-Host ''
    Write-Host '----------------------------------------' -ForegroundColor Yellow
    Write-Host "Running PETS CartPole - Seed `$seed/4" -ForegroundColor Green
    Write-Host '----------------------------------------' -ForegroundColor Yellow
    `$startTime = Get-Date
    
    python run_pets_cartpole.py --seed `$seed --output-dir ../../$outputDir
    
    `$elapsed = (Get-Date) - `$startTime
    Write-Host "Seed `$seed completed in: `$(`$elapsed.ToString('hh\:mm\:ss'))" -ForegroundColor Green
}

Write-Host ''
Write-Host '========================================' -ForegroundColor Green
Write-Host 'TERMINAL 3: PETS CartPole - ALL SEEDS COMPLETE!' -ForegroundColor Green
Write-Host '========================================' -ForegroundColor Green
Read-Host 'Press Enter to close this terminal'
"@

Start-Process powershell -ArgumentList "-NoExit", "-Command", $petsCartPoleScript

# Terminal 4: PETS Pendulum (5 seeds)
Write-Host "[Terminal 4] Starting PETS Pendulum (5 seeds)..." -ForegroundColor Magenta
$petsPendulumScript = @"
conda activate mbpsrl
cd '$PWD'
Write-Host '========================================' -ForegroundColor Cyan
Write-Host 'TERMINAL 4: PETS Pendulum (5 seeds)' -ForegroundColor Cyan
Write-Host '========================================' -ForegroundColor Cyan
Write-Host ''

cd baselines\pets

for (`$seed = 0; `$seed -lt 5; `$seed++) {
    Write-Host ''
    Write-Host '----------------------------------------' -ForegroundColor Yellow
    Write-Host "Running PETS Pendulum - Seed `$seed/4" -ForegroundColor Green
    Write-Host '----------------------------------------' -ForegroundColor Yellow
    `$startTime = Get-Date
    
    python run_pets_pendulum.py --seed `$seed --output-dir ../../$outputDir
    
    `$elapsed = (Get-Date) - `$startTime
    Write-Host "Seed `$seed completed in: `$(`$elapsed.ToString('hh\:mm\:ss'))" -ForegroundColor Green
}

Write-Host ''
Write-Host '========================================' -ForegroundColor Green
Write-Host 'TERMINAL 4: PETS Pendulum - ALL SEEDS COMPLETE!' -ForegroundColor Green
Write-Host '========================================' -ForegroundColor Green
Read-Host 'Press Enter to close this terminal'
"@

Start-Process powershell -ArgumentList "-NoExit", "-Command", $petsPendulumScript

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "All 4 terminals launched successfully!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Monitor progress in the 4 terminal windows:" -ForegroundColor Yellow
Write-Host "  Terminal 1: MBPO CartPole" -ForegroundColor Cyan
Write-Host "  Terminal 2: MBPO Pendulum" -ForegroundColor Cyan
Write-Host "  Terminal 3: PETS CartPole" -ForegroundColor Cyan
Write-Host "  Terminal 4: PETS Pendulum" -ForegroundColor Cyan
Write-Host ""
Write-Host "Expected completion times (approximate):" -ForegroundColor Yellow
Write-Host "  MBPO experiments: ~2.5-3 hours each" -ForegroundColor White
Write-Host "  PETS experiments: ~2-2.5 hours each" -ForegroundColor White
Write-Host "  Total (parallel): ~6-8 hours" -ForegroundColor White
Write-Host ""
Write-Host "Results directory: $outputDir" -ForegroundColor Green
Write-Host ""
Write-Host "Expected output files (20 total per baseline):" -ForegroundColor Yellow
Write-Host "  - mbpo_cartpole_log_seed{0-4}.txt" -ForegroundColor White
Write-Host "  - mbpo_cartpole_timestep_rewards_seed{0-4}.txt" -ForegroundColor White
Write-Host "  - mbpo_pendulum_log_seed{0-4}.txt" -ForegroundColor White
Write-Host "  - mbpo_pendulum_timestep_rewards_seed{0-4}.txt" -ForegroundColor White
Write-Host "  - pets_cartpole_log_seed{0-4}.txt" -ForegroundColor White
Write-Host "  - pets_cartpole_timestep_rewards_seed{0-4}.txt" -ForegroundColor White
Write-Host "  - pets_pendulum_log_seed{0-4}.txt" -ForegroundColor White
Write-Host "  - pets_pendulum_timestep_rewards_seed{0-4}.txt" -ForegroundColor White
Write-Host ""
Write-Host "Total: 40 files (4 experiments × 5 seeds × 2 files per seed)" -ForegroundColor Green
Write-Host ""
