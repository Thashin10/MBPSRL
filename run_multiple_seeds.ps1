# Run PSRL experiments with multiple seeds in parallel
# This replicates the paper's methodology of running multiple trials

param(
    [int]$NumSeeds = 5,
    [int]$MaxParallel = 4
)

$ErrorActionPreference = "Continue"
$CondaExe = "C:\Users\thash\Miniconda3\Scripts\conda.exe"
$EnvName = "mbpsrl"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "MULTI-SEED PSRL EXPERIMENTS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Seeds: $NumSeeds per experiment" -ForegroundColor Yellow
Write-Host "Max parallel jobs: $MaxParallel" -ForegroundColor Yellow
Write-Host "Total experiments: 4 configs × $NumSeeds seeds = $($NumSeeds * 4) runs" -ForegroundColor Yellow
Write-Host "Estimated time: ~$([math]::Ceiling(($NumSeeds * 4) / $MaxParallel * 12)) minutes with $MaxParallel parallel jobs`n" -ForegroundColor Yellow

# Create seeds directory
$SeedsDir = "seeds_data"
if (-not (Test-Path $SeedsDir)) {
    New-Item -ItemType Directory -Path $SeedsDir | Out-Null
    Write-Host "Created directory: $SeedsDir`n" -ForegroundColor Green
}

# Define experiment configurations
$experiments = @(
    @{Name="CartPole-WithOracle"; Script="run_cartpole.py"; Args="--with-reward True --num-episodes 15"},
    @{Name="CartPole-WithoutOracle"; Script="run_cartpole.py"; Args="--with-reward False --num-episodes 15"},
    @{Name="Pendulum-WithOracle"; Script="run_pendulum.py"; Args="--with-reward True"},
    @{Name="Pendulum-WithoutOracle"; Script="run_pendulum.py"; Args="--with-reward False"}
)

# Function to run single experiment
$runExperiment = {
    param($CondaExe, $EnvName, $Script, $Args, $Seed, $OutputDir, $ExpName)
    
    $timestamp = Get-Date -Format "HHmmss"
    $logFile = Join-Path $OutputDir "$ExpName-seed$Seed-$timestamp.log"
    
    # Set PYTHONHASHSEED for reproducibility
    $env:PYTHONHASHSEED = $Seed
    
    $cmd = "import numpy as np; import random; import torch; np.random.seed($Seed); random.seed($Seed); torch.manual_seed($Seed); exec(open('$Script').read())"
    
    try {
        & $CondaExe run -n $EnvName python -c $cmd $Args.Split() 2>&1 | Out-File -FilePath $logFile
        return @{Success=$true; Seed=$Seed; Exp=$ExpName; Log=$logFile}
    } catch {
        return @{Success=$false; Seed=$Seed; Exp=$ExpName; Error=$_.Exception.Message}
    }
}

# Create all jobs
$allJobs = @()
foreach ($exp in $experiments) {
    for ($seed = 0; $seed -lt $NumSeeds; $seed++) {
        $allJobs += @{
            Experiment = $exp.Name
            Script = $exp.Script
            Args = $exp.Args
            Seed = $seed
        }
    }
}

Write-Host "Starting $($allJobs.Count) experiment runs...`n" -ForegroundColor Cyan

# Run jobs in parallel with throttling
$jobs = @()
$completed = 0
$startTime = Get-Date

foreach ($jobDef in $allJobs) {
    # Wait if we've hit max parallel limit
    while (($jobs | Where-Object {$_.State -eq 'Running'}).Count -ge $MaxParallel) {
        Start-Sleep -Seconds 2
        
        # Check for completed jobs
        $finished = $jobs | Where-Object {$_.State -eq 'Completed'}
        if ($finished) {
            foreach ($job in $finished) {
                $result = Receive-Job -Job $job
                $completed++
                $elapsed = [math]::Round(((Get-Date) - $startTime).TotalMinutes, 1)
                Write-Host "[$completed/$($allJobs.Count)] Completed after $elapsed min" -ForegroundColor Green
                Remove-Job -Job $job
            }
            $jobs = $jobs | Where-Object {$_.State -ne 'Completed'}
        }
    }
    
    # Start new job
    $job = Start-Job -ScriptBlock $runExperiment -ArgumentList @(
        $CondaExe, $EnvName, $jobDef.Script, $jobDef.Args, 
        $jobDef.Seed, $SeedsDir, $jobDef.Experiment
    )
    $jobs += $job
    
    Write-Host "[STARTED] $($jobDef.Experiment) - Seed $($jobDef.Seed)" -ForegroundColor Yellow
}

# Wait for remaining jobs
Write-Host "`nWaiting for remaining jobs to complete..." -ForegroundColor Cyan
Wait-Job -Job $jobs | Out-Null

foreach ($job in $jobs) {
    $result = Receive-Job -Job $job
    $completed++
    Write-Host "[$completed/$($allJobs.Count)] Completed" -ForegroundColor Green
    Remove-Job -Job $job
}

$totalTime = [math]::Round(((Get-Date) - $startTime).TotalMinutes, 1)

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "ALL EXPERIMENTS COMPLETE!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Total time: $totalTime minutes" -ForegroundColor Yellow
Write-Host "Results saved in: $SeedsDir\" -ForegroundColor Yellow
Write-Host "`nNext step: Run aggregation script to combine seeds and generate plots" -ForegroundColor Cyan
