# Simple multi-seed runner that directly calls the Python scripts
param(
    [int]$NumSeeds = 5,
    [int]$MaxParallel = 4
)

$ErrorActionPreference = "Continue"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "MULTI-SEED PSRL EXPERIMENTS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Seeds: $NumSeeds per experiment" -ForegroundColor Yellow
Write-Host "Max parallel jobs: $MaxParallel" -ForegroundColor Yellow
$totalRuns = $NumSeeds * 4
Write-Host "Total experiments: 4 configs x $NumSeeds seeds = $totalRuns runs" -ForegroundColor Yellow
$estTime = [math]::Ceiling(($NumSeeds * 4) / $MaxParallel * 12)
Write-Host "`nThis will take approximately $estTime minutes`n" -ForegroundColor Yellow

# Create seeds directory
$SeedsDir = "seeds_data"
if (-not (Test-Path $SeedsDir)) {
    New-Item -ItemType Directory -Path $SeedsDir | Out-Null
    Write-Host "Created directory: $SeedsDir`n" -ForegroundColor Green
}

# Define experiment configurations
$experiments = @(
    @{Name="CartPole-WithOracle"; Script="run_cartpole.py"; WithReward="True"},
    @{Name="CartPole-WithoutOracle"; Script="run_cartpole.py"; WithReward="False"},
    @{Name="Pendulum-WithOracle"; Script="run_pendulum.py"; WithReward="True"},
    @{Name="Pendulum-WithoutOracle"; Script="run_pendulum.py"; WithReward="False"}
)

$startTime = Get-Date
$jobs = @()
$completed = 0

# Start all jobs
foreach ($exp in $experiments) {
    for ($seed = 0; $seed -lt $NumSeeds; $seed++) {
        # Wait if we've hit max parallel limit
        while (($jobs | Where-Object {$_.State -eq 'Running'}).Count -ge $MaxParallel) {
            Start-Sleep -Seconds 5
            
            # Check for completed jobs
            $finished = $jobs | Where-Object {$_.State -eq 'Completed'}
            if ($finished) {
                foreach ($job in $finished) {
                    $completed++
                    $elapsed = [math]::Round(((Get-Date) - $startTime).TotalMinutes, 1)
                    Write-Host "[$completed/$totalRuns] Completed after $elapsed min" -ForegroundColor Green
                    Remove-Job -Job $job
                }
                $jobs = $jobs | Where-Object {$_.State -ne 'Completed'}
            }
        }
        
        # Start new job
        $scriptBlock = {
            param($Script, $WithReward, $Seed)
            conda run -n mbpsrl --no-capture-output python $Script --with-reward $WithReward --seed $Seed 2>&1
        }
        
        $job = Start-Job -ScriptBlock $scriptBlock -ArgumentList $exp.Script, $exp.WithReward, $seed
        $jobs += $job
        
        Write-Host "[STARTED] $($exp.Name) - Seed $seed" -ForegroundColor Yellow
    }
}

# Wait for remaining jobs
Write-Host "`nWaiting for remaining jobs to complete..." -ForegroundColor Cyan
while ($jobs.Count -gt 0) {
    Start-Sleep -Seconds 5
    
    $finished = $jobs | Where-Object {$_.State -eq 'Completed'}
    foreach ($job in $finished) {
        $completed++
        $elapsed = [math]::Round(((Get-Date) - $startTime).TotalMinutes, 1)
        Write-Host "[$completed/$totalRuns] Completed after $elapsed min" -ForegroundColor Green
        
        # Show any errors
        $output = Receive-Job -Job $job 2>&1
        if ($output -match "error|exception") {
            Write-Host "  Warning: Job may have had errors" -ForegroundColor Red
        }
        
        Remove-Job -Job $job
    }
    $jobs = $jobs | Where-Object {$_.State -ne 'Completed'}
}

$totalTime = [math]::Round(((Get-Date) - $startTime).TotalMinutes, 1)

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "ALL EXPERIMENTS COMPLETE!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Total time: $totalTime minutes" -ForegroundColor Yellow

# Check results
$dataFiles = Get-ChildItem $SeedsDir -Filter "*_seed*.txt" | Measure-Object
$expectedFiles = $NumSeeds * 4 * 2
Write-Host "Data files created: $($dataFiles.Count)" -ForegroundColor Yellow

if ($dataFiles.Count -eq $expectedFiles) {
    Write-Host "[SUCCESS] All seed data files generated successfully!" -ForegroundColor Green
} else {
    Write-Host "[WARNING] Expected $expectedFiles files, found $($dataFiles.Count)" -ForegroundColor Yellow
}

Write-Host "`nNext step: Run aggregation script to generate plots" -ForegroundColor Cyan
Write-Host "Command: conda run -n mbpsrl python plot_multi_seed.py --env both --num-seeds $NumSeeds" -ForegroundColor White
