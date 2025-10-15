# Working parallel runner - Uses Start-Process with cmd.exe
# Runs one experiment at a time with 5 seeds in parallel
param(
    [int]$NumSeeds = 5
)

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "MULTI-SEED PSRL EXPERIMENTS (Parallel)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Seeds: $NumSeeds per experiment (parallel)" -ForegroundColor Yellow
Write-Host "Experiments: 4 total (sequential)" -ForegroundColor Yellow
Write-Host "Estimated time: ~48 minutes`n" -ForegroundColor Yellow

# Create seeds directory
$SeedsDir = "seeds_data"
if (-not (Test-Path $SeedsDir)) {
    New-Item -ItemType Directory -Path $SeedsDir | Out-Null
}

# Define experiments
$experiments = @(
    @{Name="CartPole-WithOracle"; Script="run_cartpole.py"; WithReward="True"},
    @{Name="CartPole-WithoutOracle"; Script="run_cartpole.py"; WithReward="False"},
    @{Name="Pendulum-WithOracle"; Script="run_pendulum.py"; WithReward="True"},
    @{Name="Pendulum-WithoutOracle"; Script="run_pendulum.py"; WithReward="False"}
)

$totalStart = Get-Date
$expNum = 0

foreach ($exp in $experiments) {
    $expNum++
    
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "[$expNum/4] $($exp.Name)" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    
    $expStart = Get-Date
    $logFiles = @()
    
    # Start all 5 seeds in parallel using Start-Process
    Write-Host "Starting $NumSeeds seeds in parallel..." -ForegroundColor Yellow
    for ($seed = 0; $seed -lt $NumSeeds; $seed++) {
        $logFile = Join-Path $PWD "seed_${seed}_$($exp.Name).log"
        $logFiles += $logFile
        
        $command = "conda run -n mbpsrl python $($exp.Script) --with-reward $($exp.WithReward) --seed $seed --num-episodes 15"
        
        Write-Host "  Starting Seed $seed..." -ForegroundColor Gray
        
        Start-Process -FilePath "cmd.exe" `
            -ArgumentList "/c $command > `"$logFile`" 2>&1" `
            -WindowStyle Hidden `
            -WorkingDirectory $PWD
    }
    
    Write-Host "`nWaiting for all seeds to complete..." -ForegroundColor Yellow
    Write-Host "(Checking every 10 seconds for completion)`n" -ForegroundColor Gray
    
    # Wait for completion by checking output files
    $completed = 0
    $checkCount = 0
    while ($completed -lt $NumSeeds) {
        Start-Sleep -Seconds 10
        $checkCount++
        
        $newCompleted = 0
        for ($seed = 0; $seed -lt $NumSeeds; $seed++) {
            # Check if both seed data files exist for this seed
            $files = Get-ChildItem $SeedsDir -Filter "*_seed${seed}.txt" -ErrorAction SilentlyContinue
            
            # Count files that match this experiment and seed
            $matchingFiles = $files | Where-Object { 
                $_.Name -like "*cartpole*" -or $_.Name -like "*pendulum*"
            }
            
            if ($matchingFiles.Count -ge 2) {
                $newCompleted++
            }
        }
        
        if ($newCompleted -gt $completed) {
            $justCompleted = $newCompleted - $completed
            Write-Host "  [$newCompleted/$NumSeeds completed] (+$justCompleted)" -ForegroundColor Green
            $completed = $newCompleted
        } else {
            $elapsed = [math]::Round(((Get-Date) - $expStart).TotalMinutes, 1)
            Write-Host "  [$completed/$NumSeeds completed] | Elapsed: $elapsed min (check #$checkCount)" -ForegroundColor Gray
        }
    }
    
    $expTime = [math]::Round(((Get-Date) - $expStart).TotalMinutes, 1)
    Write-Host "`n  COMPLETE in $expTime minutes!" -ForegroundColor Green
    
    # Clean up log files
    foreach ($log in $logFiles) {
        if (Test-Path $log) {
            Remove-Item $log -ErrorAction SilentlyContinue
        }
    }
}

$totalTime = [math]::Round(((Get-Date) - $totalStart).TotalMinutes, 1)

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "ALL EXPERIMENTS COMPLETE!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Total time: $totalTime minutes" -ForegroundColor Yellow

# Verify results
$allFiles = Get-ChildItem $SeedsDir -Filter "*_seed*.txt"
$expectedFiles = $NumSeeds * 4 * 2

Write-Host "`nResults:" -ForegroundColor Cyan
Write-Host "  Files: $($allFiles.Count) / $expectedFiles" -ForegroundColor $(if ($allFiles.Count -eq $expectedFiles) {"Green"} else {"Yellow"})

if ($allFiles.Count -eq $expectedFiles) {
    Write-Host "`n  SUCCESS!" -ForegroundColor Green
    Write-Host "`nNext: conda run -n mbpsrl python plot_multi_seed.py --env both --num-seeds $NumSeeds" -ForegroundColor White
} else {
    Write-Host "`n  WARNING: Some files missing" -ForegroundColor Yellow
}
