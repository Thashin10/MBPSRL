param(
    [int]$NumSeeds = 5
)

$ErrorActionPreference = "Continue"

$CondaExe = "C:\Users\thash\Miniconda3\Scripts\conda.exe"
$EnvName = "mbpsrl"

Write-Host "=========================================="
Write-Host "Running CartPole WITH Oracle - 5 Seeds in Parallel"
Write-Host "=========================================="
Write-Host "Expected time: ~15 minutes"
Write-Host ""

# Clean old seed data for this experiment
Write-Host "Cleaning old CartPole WITH Oracle seed files..."
Remove-Item "seeds_data\cartpole_log_with_oracle_seed*.txt" -Force -ErrorAction SilentlyContinue
Remove-Item "seeds_data\cartpole_timestep_rewards_with_oracle_seed*.txt" -Force -ErrorAction SilentlyContinue
Write-Host "Done"
Write-Host ""

# Launch all seeds in parallel
$jobs = @()
for ($seed = 0; $seed -lt $NumSeeds; $seed++) {
    Write-Host "Launching seed $seed..."
    
    $job = Start-Job -ScriptBlock {
        param($CondaPath, $Env, $SeedNum)
        & $CondaPath run -n $Env python run_cartpole.py --with-reward True --seed $SeedNum --num-episodes 15 2>&1
    } -ArgumentList $CondaExe, $EnvName, $seed
    
    $jobs += $job
    Start-Sleep -Milliseconds 500
}

Write-Host ""
Write-Host "All 5 seeds launched! Monitoring progress..."
Write-Host ""

# Monitor completion
$completed = 0
$startTime = Get-Date

while ($completed -lt $NumSeeds) {
    Start-Sleep -Seconds 10
    $elapsed = [math]::Round(((Get-Date) - $startTime).TotalMinutes, 1)
    
    $completed = 0
    for ($seed = 0; $seed -lt $NumSeeds; $seed++) {
        $file1 = "seeds_data\cartpole_log_with_oracle_seed${seed}.txt"
        $file2 = "seeds_data\cartpole_timestep_rewards_with_oracle_seed${seed}.txt"
        
        if ((Test-Path $file1) -and (Test-Path $file2)) {
            $lines = (Get-Content $file2 -ErrorAction SilentlyContinue).Count
            if ($lines -ge 3000) {
                $completed++
            }
        }
    }
    
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Elapsed: ${elapsed}m | Completed: $completed/$NumSeeds seeds"
}

Write-Host ""
Write-Host "=========================================="
Write-Host "All seeds completed!"
Write-Host "=========================================="

# Clean up jobs
$jobs | Stop-Job -ErrorAction SilentlyContinue
$jobs | Remove-Job -ErrorAction SilentlyContinue

# Show results
Write-Host ""
Write-Host "Results:"
for ($seed = 0; $seed -lt $NumSeeds; $seed++) {
    $file = "seeds_data\cartpole_timestep_rewards_with_oracle_seed${seed}.txt"
    if (Test-Path $file) {
        $lines = (Get-Content $file).Count
        Write-Host "  Seed $seed : $lines timesteps"
    }
}
