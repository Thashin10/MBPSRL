# Reliable parallel runner using full conda path and proper activation
param(
    [int]$NumSeeds = 5
)

$ErrorActionPreference = "Continue"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "MULTI-SEED PSRL EXPERIMENTS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Running $NumSeeds seeds in parallel per experiment" -ForegroundColor Yellow
Write-Host "4 experiments total" -ForegroundColor Yellow
Write-Host "Estimated: ~48 minutes`n" -ForegroundColor Yellow

# Paths
$SeedsDir = "seeds_data"
$CondaExe = "C:\Users\thash\Miniconda3\Scripts\conda.exe"
$EnvName = "mbpsrl"

if (-not (Test-Path $SeedsDir)) {
    New-Item -ItemType Directory -Path $SeedsDir | Out-Null
}

# Experiments
$experiments = @(
    @{Name="CartPole-WithOracle"; Script="run_cartpole.py"; WithReward="True"},
    @{Name="CartPole-WithoutOracle"; Script="run_cartpole.py"; WithReward="False"},
    @{Name="Pendulum-WithOracle"; Script="run_pendulum.py"; WithReward="True"},
    @{Name="Pendulum-WithoutOracle"; Script="run_pendulum.py"; WithReward="False"}
)

$totalStart = Get-Date

for ($expNum = 0; $expNum -lt $experiments.Count; $expNum++) {
    $exp = $experiments[$expNum]
    
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "[$(($expNum+1))/4] $($exp.Name)" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan
    
    $expStart = Get-Date
    
    # Launch all seeds
    Write-Host "Launching $NumSeeds parallel processes..." -ForegroundColor Yellow
    for ($seed = 0; $seed -lt $NumSeeds; $seed++) {
        $logFile = "temp_seed${seed}_$($exp.Name).log"
        
        # Build command - use full conda path
        $pythonArgs = "$($exp.Script) --with-reward $($exp.WithReward) --seed $seed --num-episodes 15"
        
        Write-Host "  Seed $seed starting..." -ForegroundColor Gray
        
        # Use cmd.exe to run conda
        $cmdArgs = "/c `"$CondaExe run -n $EnvName python $pythonArgs > $logFile 2>&1`""
        
        Start-Process -FilePath "cmd.exe" `
                      -ArgumentList $cmdArgs `
                      -WindowStyle Hidden `
                      -WorkingDirectory $PWD.Path
        
        Start-Sleep -Milliseconds 500  # Small delay between launches
    }
    
    Write-Host "`nMonitoring completion..." -ForegroundColor Yellow
    Write-Host "(Checking files every 15 seconds)`n" -ForegroundColor Gray
    
    # Wait for files to appear
    $completed = @()
    $iteration = 0
    
    while ($completed.Count -lt $NumSeeds) {
        Start-Sleep -Seconds 15
        $iteration++
        
        # Check which seeds have completed by looking for their output files
        $newCompleted = @()
        for ($seed = 0; $seed -lt $NumSeeds; $seed++) {
            if ($seed -in $completed) {
                $newCompleted += $seed
                continue
            }
            
            # Look for the timestep rewards file (this is always created last)
            $pattern = "*_seed$seed.txt"
            $files = Get-ChildItem $SeedsDir -Filter $pattern -ErrorAction SilentlyContinue
            
            # Need 2 files: log and timestep_rewards
            if ($files.Count -ge 2) {
                $newCompleted += $seed
                Write-Host "  [DONE] Seed $seed completed ($($newCompleted.Count)/$NumSeeds)" -ForegroundColor Green
            }
        }
        
        $completed = $newCompleted
        
        if ($completed.Count -lt $NumSeeds) {
            $elapsed = [math]::Round(((Get-Date) - $expStart).TotalMinutes, 1)
            Write-Host "  [WAIT] $($completed.Count)/$NumSeeds done | ${elapsed}min elapsed (check #$iteration)" -ForegroundColor Gray
        }
    }
    
    $expTime = [math]::Round(((Get-Date) - $expStart).TotalMinutes, 1)
    Write-Host "`n  EXPERIMENT COMPLETE in $expTime minutes!" -ForegroundColor Green
    
    # Clean up temp log files
    Remove-Item "temp_seed*_$($exp.Name).log" -ErrorAction SilentlyContinue
}

$totalTime = [math]::Round(((Get-Date) - $totalStart).TotalMinutes, 1)

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "ALL EXPERIMENTS COMPLETE!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Total time: $totalTime minutes`n" -ForegroundColor Yellow

# Verify
$allFiles = Get-ChildItem $SeedsDir -Filter "*_seed*.txt"
$expected = $NumSeeds * 4 * 2

Write-Host "Files created: $($allFiles.Count) / $expected" -ForegroundColor $(if ($allFiles.Count -eq $expected) {"Green"} else {"Yellow"})

if ($allFiles.Count -eq $expected) {
    Write-Host "`nSUCCESS! Ready for plotting." -ForegroundColor Green
    Write-Host "`nNext command:" -ForegroundColor Cyan
    Write-Host "  & `"$CondaExe`" run -n $EnvName python plot_multi_seed.py --env both --num-seeds $NumSeeds" -ForegroundColor White
} else {
    Write-Host "`nWARNING: Expected $expected files, got $($allFiles.Count)" -ForegroundColor Yellow
    Write-Host "Some experiments may have failed. Check log files." -ForegroundColor Yellow
}
