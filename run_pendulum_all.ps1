$ErrorActionPreference = "Continue"

$CondaExe = "C:\Users\thash\Miniconda3\Scripts\conda.exe"
$NumSeeds = 5

Write-Host "============================================================"
Write-Host "Pendulum Experiments - Both WITH and WITHOUT Oracle"
Write-Host "============================================================"
Write-Host "Running 2 experiments × 5 seeds = 10 total runs"
Write-Host "Estimated total time: ~2.5 hours (15 min per seed)"
Write-Host "Start time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "============================================================"
Write-Host ""

$experiments = @(
    @{Name="Pendulum WITH Oracle"; WithReward="True"; OracleStr="with"}
    @{Name="Pendulum WITHOUT Oracle"; WithReward="False"; OracleStr="without"}
)

$globalStart = Get-Date

for ($expIdx = 0; $expIdx -lt $experiments.Count; $expIdx++) {
    $exp = $experiments[$expIdx]
    
    Write-Host ""
    Write-Host "============================================================"
    Write-Host "EXPERIMENT $($expIdx + 1)/2: $($exp.Name)"
    Write-Host "============================================================"
    Write-Host ""
    
    $expStart = Get-Date
    
    for ($seed = 0; $seed -lt $NumSeeds; $seed++) {
        $seedStart = Get-Date
        
        Write-Host "------------------------------------------------------------"
        Write-Host "Seed $seed / $($NumSeeds - 1) for $($exp.Name)"
        Write-Host "------------------------------------------------------------"
        Write-Host "Running: python run_pendulum.py --with-reward $($exp.WithReward) --seed $seed --num-episodes 15"
        Write-Host ""
        
        & $CondaExe run -n mbpsrl python run_pendulum.py --with-reward $($exp.WithReward) --seed $seed --num-episodes 15
        
        $seedElapsed = [math]::Round(((Get-Date) - $seedStart).TotalMinutes, 1)
        $expElapsed = [math]::Round(((Get-Date) - $expStart).TotalMinutes, 1)
        $totalElapsed = [math]::Round(((Get-Date) - $globalStart).TotalMinutes, 1)
        
        Write-Host ""
        Write-Host "[COMPLETE] Seed $seed finished in ${seedElapsed} minutes"
        Write-Host "[EXPERIMENT PROGRESS] ${expElapsed} minutes elapsed for this experiment"
        Write-Host "[TOTAL PROGRESS] ${totalElapsed} minutes elapsed overall"
        
        # Verify output
        $file = "seeds_data\pendulum_timestep_rewards_$($exp.OracleStr)_oracle_seed${seed}.txt"
        
        if (Test-Path $file) {
            $lines = (Get-Content $file).Count
            if ($lines -ge 3000) {
                Write-Host "[SUCCESS] Seed $seed : $lines timesteps (COMPLETE)"
            } else {
                Write-Host "[WARNING] Seed $seed : $lines timesteps (INCOMPLETE - expected 3000)"
            }
        } else {
            Write-Host "[ERROR] Seed $seed : Output file not found!"
        }
        Write-Host ""
    }
    
    $expTotal = [math]::Round(((Get-Date) - $expStart).TotalMinutes, 1)
    Write-Host "============================================================"
    Write-Host "EXPERIMENT $($expIdx + 1)/2 COMPLETE: $($exp.Name)"
    Write-Host "Time: ${expTotal} minutes"
    Write-Host "============================================================"
    Write-Host ""
}

$totalTime = [math]::Round(((Get-Date) - $globalStart).TotalMinutes, 1)
$totalHours = [math]::Round($totalTime / 60, 2)

Write-Host ""
Write-Host "============================================================"
Write-Host "ALL PENDULUM EXPERIMENTS COMPLETE!"
Write-Host "============================================================"
Write-Host "End time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "Total time: ${totalTime} minutes (${totalHours} hours)"
Write-Host ""
Write-Host "FINAL RESULTS:"
Write-Host "============================================================"

foreach ($exp in $experiments) {
    Write-Host ""
    Write-Host "$($exp.Name):"
    for ($seed = 0; $seed -lt $NumSeeds; $seed++) {
        $file = "seeds_data\pendulum_timestep_rewards_$($exp.OracleStr)_oracle_seed${seed}.txt"
        
        if (Test-Path $file) {
            $lines = (Get-Content $file).Count
            if ($lines -ge 3000) {
                Write-Host "  Seed $seed : $lines timesteps OK"
            } else {
                Write-Host "  Seed $seed : $lines timesteps (INCOMPLETE)"
            }
        } else {
            Write-Host "  Seed $seed : MISSING"
        }
    }
}

Write-Host ""
Write-Host "============================================================"
Write-Host "Ready to generate plots!"
Write-Host "============================================================"
