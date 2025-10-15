# Sequential multi-seed runner - runs experiments one at a time
# More reliable than parallel jobs, shows real-time output
param(
    [int]$NumSeeds = 5
)

$ErrorActionPreference = "Stop"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "MULTI-SEED PSRL EXPERIMENTS (Sequential)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Seeds: $NumSeeds per experiment" -ForegroundColor Yellow
$totalRuns = $NumSeeds * 4
Write-Host "Total experiments: 4 configs x $NumSeeds seeds = $totalRuns runs" -ForegroundColor Yellow
$estTime = $totalRuns * 12
Write-Host "`nEstimated time: ~$estTime minutes (running sequentially)`n" -ForegroundColor Yellow

# Create seeds directory
$SeedsDir = "seeds_data"
if (-not (Test-Path $SeedsDir)) {
    New-Item -ItemType Directory -Path $SeedsDir | Out-Null
    Write-Host "Created directory: $SeedsDir`n" -ForegroundColor Green
}

$startTime = Get-Date
$completed = 0

# Define experiments
$experiments = @(
    @{Name="CartPole-WithOracle"; Script="run_cartpole.py"; Args="--with-reward True --num-episodes 15"},
    @{Name="CartPole-WithoutOracle"; Script="run_cartpole.py"; Args="--with-reward False --num-episodes 15"},
    @{Name="Pendulum-WithOracle"; Script="run_pendulum.py"; Args="--with-reward True"},
    @{Name="Pendulum-WithoutOracle"; Script="run_pendulum.py"; Args="--with-reward False"}
)

# Run all experiments
foreach ($exp in $experiments) {
    for ($seed = 0; $seed -lt $NumSeeds; $seed++) {
        $completed++
        $elapsed = [math]::Round(((Get-Date) - $startTime).TotalMinutes, 1)
        
        Write-Host "`n========================================" -ForegroundColor Cyan
        Write-Host "[$completed/$totalRuns] $($exp.Name) - Seed $seed" -ForegroundColor Yellow
        Write-Host "Elapsed: $elapsed min" -ForegroundColor Gray
        Write-Host "========================================" -ForegroundColor Cyan
        
        $argList = $exp.Args + " --seed $seed"
        
        try {
            conda run -n mbpsrl --no-capture-output python $exp.Script $argList.Split()
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✓ Completed successfully" -ForegroundColor Green
            } else {
                Write-Host "⚠ Warning: Exit code $LASTEXITCODE" -ForegroundColor Yellow
            }
        }
        catch {
            Write-Host "✗ Error: $_" -ForegroundColor Red
        }
    }
}

$totalTime = [math]::Round(((Get-Date) - $startTime).TotalMinutes, 1)

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "ALL EXPERIMENTS COMPLETE!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Total time: $totalTime minutes" -ForegroundColor Yellow

# Check results
$dataFiles = Get-ChildItem $SeedsDir -Filter "*_seed*.txt" | Measure-Object
$expectedFiles = $NumSeeds * 4 * 2
Write-Host "Data files created: $($dataFiles.Count) / $expectedFiles" -ForegroundColor Yellow

if ($dataFiles.Count -eq $expectedFiles) {
    Write-Host "[SUCCESS] All seed data files generated!" -ForegroundColor Green
} else {
    Write-Host "[WARNING] Expected $expectedFiles files, found $($dataFiles.Count)" -ForegroundColor Yellow
}

Write-Host "`nNext step: Run aggregation script" -ForegroundColor Cyan
Write-Host "Command: conda run -n mbpsrl python plot_multi_seed.py --env both --num-seeds $NumSeeds" -ForegroundColor White
