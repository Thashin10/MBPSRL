# Reliable multi-seed runner - Runs one experiment at a time, 5 seeds in parallel
# Uses direct process spawning instead of PowerShell jobs
param(
    [int]$NumSeeds = 5
)

$ErrorActionPreference = "Stop"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "MULTI-SEED PSRL EXPERIMENTS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Strategy: One experiment at a time, all seeds in parallel" -ForegroundColor Yellow
Write-Host "Seeds: $NumSeeds (parallel workers)" -ForegroundColor Yellow
Write-Host "Experiments: 4 total" -ForegroundColor Yellow
$estTime = 4 * 12
Write-Host "Estimated time: ~$estTime minutes`n" -ForegroundColor Yellow

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

# Run each experiment
foreach ($exp in $experiments) {
    $expNum++
    
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "EXPERIMENT $expNum/4: $($exp.Name)" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Starting $NumSeeds seeds in parallel...`n" -ForegroundColor Yellow
    
    $expStartTime = Get-Date
    $processes = @()
    
    # Start all seeds as separate processes
    for ($seed = 0; $seed -lt $NumSeeds; $seed++) {
        $argList = $exp.Args + " --seed $seed"
        
        Write-Host "  [STARTING] Seed $seed" -ForegroundColor Gray
        
        # Build the command
        $pythonCmd = "conda run -n mbpsrl python $($exp.Script) $argList"
        
        # Start process
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = "powershell.exe"
        $psi.Arguments = "-NoProfile -Command `"$pythonCmd`""
        $psi.UseShellExecute = $false
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.WorkingDirectory = $PWD.Path
        
        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = $psi
        $process.Start() | Out-Null
        
        $processes += @{
            Process = $process
            Seed = $seed
            Started = Get-Date
        }
    }
    
    Write-Host "`nAll $NumSeeds seeds started. Monitoring progress...`n" -ForegroundColor Yellow
    
    # Monitor processes
    $completed = 0
    while ($processes.Count -gt 0) {
        Start-Sleep -Seconds 5
        
        # Check for finished processes
        $stillRunning = @()
        foreach ($p in $processes) {
            if ($p.Process.HasExited) {
                $completed++
                $exitCode = $p.Process.ExitCode
                
                if ($exitCode -eq 0) {
                    Write-Host "  [DONE] Seed $($p.Seed) completed successfully ($completed/$NumSeeds)" -ForegroundColor Green
                } else {
                    Write-Host "  [WARN] Seed $($p.Seed) exited with code $exitCode ($completed/$NumSeeds)" -ForegroundColor Yellow
                }
                
                $p.Process.Dispose()
            } else {
                $stillRunning += $p
            }
        }
        
        $processes = $stillRunning
        
        # Show progress
        if ($processes.Count -gt 0) {
            $elapsed = [math]::Round(((Get-Date) - $expStartTime).TotalMinutes, 1)
            Write-Host "  [RUNNING] $($processes.Count) seeds still running | Elapsed: $elapsed min" -ForegroundColor Gray
        }
    }
    
    $expTime = [math]::Round(((Get-Date) - $expStartTime).TotalMinutes, 1)
    Write-Host "`n  EXPERIMENT COMPLETE in $expTime minutes" -ForegroundColor Green
    
    # Verify files
    $expPattern = if ($exp.Name -like "*CartPole*") { "cartpole" } else { "pendulum" }
    $oraclePattern = if ($exp.Name -like "*WithOracle*") { "with_oracle" } else { "without_oracle" }
    $searchPattern = "${expPattern}_*_${oraclePattern}_seed*.txt"
    
    $expFiles = Get-ChildItem $SeedsDir -Filter $searchPattern -ErrorAction SilentlyContinue
    Write-Host "  Files found: $($expFiles.Count) / $($NumSeeds * 2)" -ForegroundColor $(if ($expFiles.Count -eq $NumSeeds * 2) { "Green" } else { "Yellow" })
}

$totalTime = [math]::Round(((Get-Date) - $totalStartTime).TotalMinutes, 1)

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "ALL EXPERIMENTS COMPLETE!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Total time: $totalTime minutes" -ForegroundColor Yellow

# Final verification
$allFiles = Get-ChildItem $SeedsDir -Filter "*_seed*.txt" -ErrorAction SilentlyContinue
$expectedFiles = $NumSeeds * 4 * 2

Write-Host "`nFinal Results:" -ForegroundColor Cyan
Write-Host "  Files created: $($allFiles.Count) / $expectedFiles" -ForegroundColor $(if ($allFiles.Count -eq $expectedFiles) { "Green" } else { "Yellow" })

if ($allFiles.Count -eq $expectedFiles) {
    Write-Host "`n  SUCCESS! All seed data files generated." -ForegroundColor Green
    Write-Host "`nNext step: Generate plots with confidence intervals" -ForegroundColor Cyan
    Write-Host "  conda run -n mbpsrl python plot_multi_seed.py --env both --num-seeds $NumSeeds" -ForegroundColor White
} else {
    Write-Host "`n  WARNING: Some files missing. Check seeds_data directory." -ForegroundColor Yellow
    Write-Host "  Expected: $expectedFiles files" -ForegroundColor Yellow
    Write-Host "  Found: $($allFiles.Count) files" -ForegroundColor Yellow
}
