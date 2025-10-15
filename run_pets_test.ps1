# Quick PETS test with reduced parameters
# Tests both CartPole and Pendulum with 2 seeds each

$ErrorActionPreference = "Continue"
$CondaExe = "C:\Users\thash\Miniconda3\Scripts\conda.exe"

Write-Host "============================================================"
Write-Host "PETS Quick Test - Reduced Parameters"
Write-Host "============================================================"
Write-Host "Testing 2 environments × 2 seeds = 4 runs"
Write-Host "Reduced parameters: 100 trajs, 15 horizon, 3 iters"
Write-Host "Expected time: ~20-30 minutes total"
Write-Host "============================================================"
Write-Host ""

$startTime = Get-Date

# Test configurations
$tests = @(
    @{Name="PETS CartPole"; Script="baselines/pets/run_pets_cartpole.py"}
    @{Name="PETS Pendulum"; Script="baselines/pets/run_pets_pendulum.py"}
)

$NumSeeds = 2

foreach ($test in $tests) {
    Write-Host "`n=========================================="
    Write-Host $test.Name
    Write-Host "=========================================="
    
    for ($seed = 0; $seed -lt $NumSeeds; $seed++) {
        $testStart = Get-Date
        
        Write-Host "`nSeed $seed - Starting..."
        
        & $CondaExe run -n mbpsrl python -u $test.Script `
            --seed $seed `
            --num-episodes 15 `
            --num-trajs 100 `
            --plan-hor 15 `
            --max-iters 3
        
        $elapsed = [math]::Round(((Get-Date) - $testStart).TotalMinutes, 1)
        Write-Host "Seed $seed completed in $elapsed minutes"
    }
}

$totalTime = [math]::Round(((Get-Date) - $startTime).TotalMinutes, 1)
Write-Host "`n============================================================"
Write-Host "All tests completed in $totalTime minutes"
Write-Host "============================================================"

# Verify files
Write-Host "`nVerifying output files..."
$expectedFiles = @(
    "pets_cartpole_log_seed0.txt",
    "pets_cartpole_timestep_rewards_seed0.txt",
    "pets_cartpole_log_seed1.txt",
    "pets_cartpole_timestep_rewards_seed1.txt",
    "pets_pendulum_log_seed0.txt",
    "pets_pendulum_timestep_rewards_seed0.txt",
    "pets_pendulum_log_seed1.txt",
    "pets_pendulum_timestep_rewards_seed1.txt"
)

foreach ($file in $expectedFiles) {
    $path = "seeds_data\$file"
    if (Test-Path $path) {
        $lines = (Get-Content $path | Measure-Object -Line).Lines
        Write-Host "✓ $file ($lines timesteps)"
    } else {
        Write-Host "✗ $file - MISSING"
    }
}
