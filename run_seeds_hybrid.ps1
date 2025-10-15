# Hybrid runner - runs experiments sequentially, but seeds in parallel
# Best of both worlds: reliable + faster
param(
    [int]$NumSeeds = 5,
    [int]$MaxParallelSeeds = 5  # Run all seeds in parallel for each experiment
)

$ErrorActionPreference = "Continue"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "MULTI-SEED PSRL EXPERIMENTS (Hybrid)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Strategy: Run experiments sequentially, seeds in parallel" -ForegroundColor Yellow
Write-Host "Seeds per experiment: $NumSeeds (run in parallel)" -ForegroundColor Yellow
Write-Host "Total experiments: 4 configs" -ForegroundColor Yellow
$estTime = 4 * 12  # 4 experiments, each takes ~12 min (seeds run in parallel)
Write-Host "`nEstimated time: ~$estTime minutes`n" -ForegroundColor Yellow

# Create seeds directory
$SeedsDir = "seeds_data"
if (-not (Test-Path $SeedsDir)) {
    New-Item -ItemType Directory -Path $SeedsDir | Out-Null
    Write-Host "Created directory: $SeedsDir`n" -ForegroundColor Green
}

# Define experiments
$experiments = @(
    @{Name="CartPole-WithOracle"; Script="run_cartpole.py"; Args="--with-reward True --num-episodes 15"},
    @{Name="CartPole-WithoutOracle"; Script="run_cartpole.py"; Args="--with-reward False --num-episodes 15"},
    @{Name="Pendulum-WithOracle"; Script="run_pendulum.py"; Args="--with-reward True"},
    @{Name="Pendulum-WithoutOracle"; Script="run_pendulum.py"; Args="--with-reward False"}
)

$totalStartTime = Get-Date
$expNum = 0

# Run each experiment configuration
foreach ($exp in $experiments) {
    $expNum++
    
    Write-Host "`n" + "="*60 -ForegroundColor Cyan
    Write-Host "EXPERIMENT $expNum/4: $($exp.Name)" -ForegroundColor Cyan
    Write-Host "="*60 -ForegroundColor Cyan
    Write-Host "Running $NumSeeds seeds in parallel..." -ForegroundColor Yellow
    
    $expStartTime = Get-Date
    $jobs = @()
    
    # Start all seeds for this experiment in parallel
    for ($seed = 0; $seed -lt $NumSeeds; $seed++) {
        $argList = $exp.Args + " --seed $seed"
        
        Write-Host "  [STARTING] Seed $seed" -ForegroundColor Gray
        
        # Start job
        $job = Start-Job -ScriptBlock {
            param($ScriptName, $Arguments)
            Set-Location $using:PWD
            conda run -n mbpsrl --no-capture-output python $ScriptName $Arguments.Split() 2>&1
        } -ArgumentList $exp.Script, $argList
        
        $jobs += $job
    }
    
    Write-Host "`n  Waiting for all $NumSeeds seeds to complete..." -ForegroundColor Yellow
    
    # Wait for all seeds to complete with progress updates
    $completed = 0
    while ($jobs.Count -gt 0) {
        Start-Sleep -Seconds 10
        
        $finished = $jobs | Where-Object {$_.State -eq 'Completed' -or $_.State -eq 'Failed'}
        if ($finished) {
            foreach ($job in $finished) {
                $completed++
                $output = Receive-Job -Job $job -ErrorAction SilentlyContinue
                
                # Check if successful by looking for final output
                if ($output -match "Final cumulative reward") {
                    Write-Host "  ✓ Seed completed successfully ($completed/$NumSeeds)" -ForegroundColor Green
                } else {
                    Write-Host "  ⚠ Seed completed with warnings ($completed/$NumSeeds)" -ForegroundColor Yellow
                }
                
                Remove-Job -Job $job
            }
            $jobs = $jobs | Where-Object {$_.State -ne 'Completed' -and $_.State -ne 'Failed'}
        }
        
        # Show progress
        $running = $jobs.Count
        if ($running -gt 0) {
            $elapsed = [math]::Round(((Get-Date) - $expStartTime).TotalMinutes, 1)
            Write-Host "  ⏳ Still running: $running seeds | Elapsed: $elapsed min" -ForegroundColor Gray
        }
    }
    
    $expTime = [math]::Round(((Get-Date) - $expStartTime).TotalMinutes, 1)
    Write-Host "`n  ✅ $($exp.Name) complete in $expTime minutes" -ForegroundColor Green
    
    # Check files for this experiment
    $pattern = "*" + ($exp.Name -replace "-", "_").ToLower() + "*_seed*.txt"
    $expFiles = Get-ChildItem $SeedsDir -Filter $pattern -ErrorAction SilentlyContinue | Measure-Object
    Write-Host "  📁 Files created: $($expFiles.Count) / $($NumSeeds * 2)" -ForegroundColor Gray
}

$totalTime = [math]::Round(((Get-Date) - $totalStartTime).TotalMinutes, 1)

Write-Host "`n" + "="*60 -ForegroundColor Cyan
Write-Host "ALL EXPERIMENTS COMPLETE!" -ForegroundColor Green
Write-Host "="*60 -ForegroundColor Cyan
Write-Host "Total time: $totalTime minutes" -ForegroundColor Yellow

# Final check
$allFiles = Get-ChildItem $SeedsDir -Filter "*_seed*.txt" -ErrorAction SilentlyContinue | Measure-Object
$expectedFiles = $NumSeeds * 4 * 2
Write-Host "`nFinal Results:" -ForegroundColor Cyan
Write-Host "  Total files created: $($allFiles.Count) / $expectedFiles" -ForegroundColor Yellow

if ($allFiles.Count -eq $expectedFiles) {
    Write-Host "  [SUCCESS] All seed data files generated!" -ForegroundColor Green
} else {
    Write-Host "  [WARNING] Expected $expectedFiles files, found $($allFiles.Count)" -ForegroundColor Yellow
    Write-Host "  Some experiments may have failed. Check seeds_data/ directory." -ForegroundColor Yellow
}

Write-Host "`n" + "="*60 -ForegroundColor Cyan
Write-Host "NEXT STEP: Generate plots with confidence intervals" -ForegroundColor Cyan
Write-Host "="*60 -ForegroundColor Cyan
Write-Host "Command: conda run -n mbpsrl python plot_multi_seed.py --env both --num-seeds $NumSeeds" -ForegroundColor White
Write-Host ""
