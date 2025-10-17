# Quick test of all optimized baseline experiments
# Tests: 4 experiments × 1 seed × 2 episodes
# Expected time: ~5-10 minutes total

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Quick Test: All Optimized Baselines" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Running quick test with:" -ForegroundColor Yellow
Write-Host "  - 1 seed (seed 0)" -ForegroundColor White
Write-Host "  - 2 episodes per experiment" -ForegroundColor White
Write-Host "  - 4 experiments total" -ForegroundColor White
Write-Host ""
Write-Host "Expected time: ~5-10 minutes" -ForegroundColor Yellow
Write-Host ""

# Activate conda environment
Write-Host "Activating conda environment 'mbpsrl'..." -ForegroundColor Cyan
conda activate mbpsrl

# Create test output directory
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$outputDir = "test_output_$timestamp"
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
Write-Host "Test results will be saved to: $outputDir" -ForegroundColor Green
Write-Host ""

# Terminal 1: MBPO CartPole (quick test)
Write-Host "[Terminal 1] Starting MBPO CartPole test..." -ForegroundColor Magenta
$mbpoCartPoleScript = @"
conda activate mbpsrl
cd '$PWD'
Write-Host '========================================' -ForegroundColor Cyan
Write-Host 'TEST 1/4: MBPO CartPole' -ForegroundColor Cyan
Write-Host '========================================' -ForegroundColor Cyan
Write-Host ''

cd baselines\mbpo
`$startTime = Get-Date

python run_mbpo_cartpole.py --seed 0 --num-episodes 2 --output-dir ../../$outputDir

`$elapsed = (Get-Date) - `$startTime
Write-Host ''
Write-Host 'Test 1 completed in: '`$(`$elapsed.ToString('hh\:mm\:ss')) -ForegroundColor Green
Write-Host ''
Write-Host 'Expected files:' -ForegroundColor Yellow
Write-Host '  - mbpo_cartpole_log_seed0.txt' -ForegroundColor White
Write-Host '  - mbpo_cartpole_timestep_rewards_seed0.txt' -ForegroundColor White
Write-Host ''
Read-Host 'Press Enter to close this terminal'
"@

Start-Process powershell -ArgumentList "-NoExit", "-Command", $mbpoCartPoleScript

Start-Sleep -Seconds 1

# Terminal 2: MBPO Pendulum (quick test)
Write-Host "[Terminal 2] Starting MBPO Pendulum test..." -ForegroundColor Magenta
$mbpoPendulumScript = @"
conda activate mbpsrl
cd '$PWD'
Write-Host '========================================' -ForegroundColor Cyan
Write-Host 'TEST 2/4: MBPO Pendulum' -ForegroundColor Cyan
Write-Host '========================================' -ForegroundColor Cyan
Write-Host ''

cd baselines\mbpo
`$startTime = Get-Date

python run_mbpo_pendulum.py --seed 0 --num-episodes 2 --output-dir ../../$outputDir

`$elapsed = (Get-Date) - `$startTime
Write-Host ''
Write-Host 'Test 2 completed in: '`$(`$elapsed.ToString('hh\:mm\:ss')) -ForegroundColor Green
Write-Host ''
Write-Host 'Expected files:' -ForegroundColor Yellow
Write-Host '  - mbpo_pendulum_log_seed0.txt' -ForegroundColor White
Write-Host '  - mbpo_pendulum_timestep_rewards_seed0.txt' -ForegroundColor White
Write-Host ''
Read-Host 'Press Enter to close this terminal'
"@

Start-Process powershell -ArgumentList "-NoExit", "-Command", $mbpoPendulumScript

Start-Sleep -Seconds 1

# Terminal 3: PETS CartPole (quick test)
Write-Host "[Terminal 3] Starting PETS CartPole test..." -ForegroundColor Magenta
$petsCartPoleScript = @"
conda activate mbpsrl
cd '$PWD'
Write-Host '========================================' -ForegroundColor Cyan
Write-Host 'TEST 3/4: PETS CartPole' -ForegroundColor Cyan
Write-Host '========================================' -ForegroundColor Cyan
Write-Host ''

cd baselines\pets
`$startTime = Get-Date

python run_pets_cartpole.py --seed 0 --num-episodes 2 --output-dir ../../$outputDir

`$elapsed = (Get-Date) - `$startTime
Write-Host ''
Write-Host 'Test 3 completed in: '`$(`$elapsed.ToString('hh\:mm\:ss')) -ForegroundColor Green
Write-Host ''
Write-Host 'Expected files:' -ForegroundColor Yellow
Write-Host '  - pets_cartpole_log_seed0.txt' -ForegroundColor White
Write-Host '  - pets_cartpole_timestep_rewards_seed0.txt' -ForegroundColor White
Write-Host ''
Read-Host 'Press Enter to close this terminal'
"@

Start-Process powershell -ArgumentList "-NoExit", "-Command", $petsCartPoleScript

Start-Sleep -Seconds 1

# Terminal 4: PETS Pendulum (quick test)
Write-Host "[Terminal 4] Starting PETS Pendulum test..." -ForegroundColor Magenta
$petsPendulumScript = @"
conda activate mbpsrl
cd '$PWD'
Write-Host '========================================' -ForegroundColor Cyan
Write-Host 'TEST 4/4: PETS Pendulum' -ForegroundColor Cyan
Write-Host '========================================' -ForegroundColor Cyan
Write-Host ''

cd baselines\pets
`$startTime = Get-Date

python run_pets_pendulum.py --seed 0 --num-episodes 2 --output-dir ../../$outputDir

`$elapsed = (Get-Date) - `$startTime
Write-Host ''
Write-Host 'Test 4 completed in: '`$(`$elapsed.ToString('hh\:mm\:ss')) -ForegroundColor Green
Write-Host ''
Write-Host 'Expected files:' -ForegroundColor Yellow
Write-Host '  - pets_pendulum_log_seed0.txt' -ForegroundColor White
Write-Host '  - pets_pendulum_timestep_rewards_seed0.txt' -ForegroundColor White
Write-Host ''
Read-Host 'Press Enter to close this terminal'
"@

Start-Process powershell -ArgumentList "-NoExit", "-Command", $petsPendulumScript

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "All 4 test terminals launched!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Monitor progress in the 4 terminal windows" -ForegroundColor Yellow
Write-Host ""
Write-Host "Expected completion time: ~5-10 minutes" -ForegroundColor Yellow
Write-Host ""
Write-Host "Test output directory: $outputDir" -ForegroundColor Green
Write-Host ""
Write-Host "After tests complete, check for 8 files:" -ForegroundColor Yellow
Write-Host "  1. mbpo_cartpole_log_seed0.txt" -ForegroundColor White
Write-Host "  2. mbpo_cartpole_timestep_rewards_seed0.txt" -ForegroundColor White
Write-Host "  3. mbpo_pendulum_log_seed0.txt" -ForegroundColor White
Write-Host "  4. mbpo_pendulum_timestep_rewards_seed0.txt" -ForegroundColor White
Write-Host "  5. pets_cartpole_log_seed0.txt" -ForegroundColor White
Write-Host "  6. pets_cartpole_timestep_rewards_seed0.txt" -ForegroundColor White
Write-Host "  7. pets_pendulum_log_seed0.txt" -ForegroundColor White
Write-Host "  8. pets_pendulum_timestep_rewards_seed0.txt" -ForegroundColor White
Write-Host ""
Write-Host "Waiting 15 seconds, then checking if tests started..." -ForegroundColor Cyan
Start-Sleep -Seconds 15

# Check if output directory has any files
if (Test-Path $outputDir) {
    $fileCount = (Get-ChildItem -Path $outputDir -File | Measure-Object).Count
    Write-Host ""
    Write-Host "Current status:" -ForegroundColor Cyan
    Write-Host "  Files created so far: $fileCount / 8" -ForegroundColor $(if ($fileCount -gt 0) { 'Green' } else { 'Yellow' })
    
    if ($fileCount -gt 0) {
        Write-Host ""
        Write-Host "Files found:" -ForegroundColor Green
        Get-ChildItem -Path $outputDir -File | ForEach-Object {
            $size = [math]::Round($_.Length / 1KB, 2)
            Write-Host "  - $($_.Name) (${size} KB)" -ForegroundColor White
        }
    } else {
        Write-Host ""
        Write-Host "No files yet - experiments may still be initializing..." -ForegroundColor Yellow
    }
} else {
    Write-Host ""
    Write-Host "Output directory not created yet - experiments may still be starting..." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Keep monitoring the 4 terminal windows for progress!" -ForegroundColor Cyan
Write-Host ""
