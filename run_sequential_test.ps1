# Quick test of all optimized baseline experiments
# Tests: 4 experiments × 1 seed × 2 episodes
# Expected time: ~5-10 minutes total

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Quick Test: All Optimized Baselines" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Create test output directory
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$outputDir = "test_output_$timestamp"
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
Write-Host "Test results will be saved to: $outputDir" -ForegroundColor Green
Write-Host ""

# Test 1: MBPO CartPole
Write-Host "[1/4] Testing MBPO CartPole..." -ForegroundColor Yellow
$startTime = Get-Date
Push-Location baselines\mbpo
python run_mbpo_cartpole.py --seed 0 --num-episodes 2 --output-dir "..\..\$outputDir"
Pop-Location
$elapsed = (Get-Date) - $startTime
Write-Host "  Completed in: $($elapsed.ToString('mm\:ss'))" -ForegroundColor Green
Write-Host ""

# Test 2: MBPO Pendulum
Write-Host "[2/4] Testing MBPO Pendulum..." -ForegroundColor Yellow
$startTime = Get-Date
Push-Location baselines\mbpo
python run_mbpo_pendulum.py --seed 0 --num-episodes 2 --output-dir "..\..\$outputDir"
Pop-Location
$elapsed = (Get-Date) - $startTime
Write-Host "  Completed in: $($elapsed.ToString('mm\:ss'))" -ForegroundColor Green
Write-Host ""

# Test 3: PETS CartPole
Write-Host "[3/4] Testing PETS CartPole..." -ForegroundColor Yellow
$startTime = Get-Date
Push-Location baselines\pets
python run_pets_cartpole.py --seed 0 --num-episodes 2 --output-dir "..\..\$outputDir"
Pop-Location
$elapsed = (Get-Date) - $startTime
Write-Host "  Completed in: $($elapsed.ToString('mm\:ss'))" -ForegroundColor Green
Write-Host ""

# Test 4: PETS Pendulum
Write-Host "[4/4] Testing PETS Pendulum..." -ForegroundColor Yellow
$startTime = Get-Date
Push-Location baselines\pets
python run_pets_pendulum.py --seed 0 --num-episodes 2 --output-dir "..\..\$outputDir"
Pop-Location
$elapsed = (Get-Date) - $startTime
Write-Host "  Completed in: $($elapsed.ToString('mm\:ss'))" -ForegroundColor Green
Write-Host ""

# Verify output files
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Verification: Checking Output Files" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$expectedFiles = @(
    "mbpo_cartpole_log_seed0.txt",
    "mbpo_cartpole_timestep_rewards_seed0.txt",
    "mbpo_pendulum_log_seed0.txt",
    "mbpo_pendulum_timestep_rewards_seed0.txt",
    "pets_cartpole_log_seed0.txt",
    "pets_cartpole_timestep_rewards_seed0.txt",
    "pets_pendulum_log_seed0.txt",
    "pets_pendulum_timestep_rewards_seed0.txt"
)

$allGood = $true
foreach ($file in $expectedFiles) {
    $filePath = Join-Path $outputDir $file
    if (Test-Path $filePath) {
        $size = (Get-Item $filePath).Length
        $sizeKB = [math]::Round($size / 1KB, 2)
        Write-Host "  [OK] $file ($sizeKB KB)" -ForegroundColor Green
    } else {
        Write-Host "  [MISSING] $file" -ForegroundColor Red
        $allGood = $false
    }
}

Write-Host ""
if ($allGood) {
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "SUCCESS: All tests passed!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "All 8 files created successfully." -ForegroundColor Green
    Write-Host "The parallel script should work correctly." -ForegroundColor Green
} else {
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "WARNING: Some files missing" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Check the terminal output above for errors." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Output directory: $outputDir" -ForegroundColor Cyan
Write-Host ""
