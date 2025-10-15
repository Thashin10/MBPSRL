param(
    [int]$NumSeeds = 5
)

$ErrorActionPreference = "Continue"

$CondaExe = "C:\Users\thash\Miniconda3\Scripts\conda.exe"
$EnvName = "mbpsrl"
$SeedsDir = "seeds_data"

Write-Host "=================================="
Write-Host "Multi-Seed Experiment Runner"
Write-Host "=================================="
Write-Host "Conda: $CondaExe"
Write-Host "Environment: $EnvName"
Write-Host "Number of seeds: $NumSeeds"
Write-Host ""

if (Test-Path $SeedsDir) {
    Write-Host "[CLEAN] Removing old seed data files..."
    Remove-Item "$SeedsDir\*_seed*.txt" -Force -ErrorAction SilentlyContinue
    Write-Host "[CLEAN] Old files removed"
} else {
    New-Item -ItemType Directory -Path $SeedsDir | Out-Null
    Write-Host "[INFO] Created $SeedsDir directory"
}

Start-Sleep -Seconds 2

$experiments = @(
    @{Name="CartPole WITH Oracle"; Script="run_cartpole.py"; WithReward="True"},
    @{Name="CartPole WITHOUT Oracle"; Script="run_cartpole.py"; WithReward="False"},
    @{Name="Pendulum WITH Oracle"; Script="run_pendulum.py"; WithReward="True"},
    @{Name="Pendulum WITHOUT Oracle"; Script="run_pendulum.py"; WithReward="False"}
)

$logdir = "temp_logs"
if (-not (Test-Path $logdir)) {
    New-Item -ItemType Directory -Path $logdir | Out-Null
}

foreach ($exp in $experiments) {
    $expName = $exp.Name
    $scriptPath = $exp.Script
    $withReward = $exp.WithReward
    
    Write-Host ""
    Write-Host "=========================================="
    Write-Host "Experiment: $expName"
    Write-Host "=========================================="
    
    $batFiles = @()
    $logFiles = @()
    
    Write-Host "Creating batch files and launching $NumSeeds seeds..."
    
    for ($seed = 0; $seed -lt $NumSeeds; $seed++) {
        $batFile = "run_seed${seed}.bat"
        $logFile = "$logdir\seed${seed}.log"
        
        $batContent = "`"$CondaExe`" run -n $EnvName python $scriptPath --with-reward $withReward --seed $seed --num-episodes 15 > `"$logFile`" 2>&1"
        
        Set-Content -Path $batFile -Value $batContent -Encoding ASCII
        
        $batFiles += $batFile
        $logFiles += $logFile
        
        Start-Process -FilePath $batFile -WindowStyle Hidden
        Write-Host "  [LAUNCH] Seed $seed started"
        Start-Sleep -Milliseconds 500
    }
    
    Write-Host ""
    Write-Host "Monitoring completion (checking every 20 seconds)..."
    
    $maxChecks = 100
    $checkCount = 0
    
    while ($checkCount -lt $maxChecks) {
        Start-Sleep -Seconds 20
        $checkCount++
        
        $completedCount = 0
        
        for ($seed = 0; $seed -lt $NumSeeds; $seed++) {
            $envPrefix = if ($scriptPath -like "*cartpole*") { "cartpole" } else { "pendulum" }
            $oracleStr = if ($withReward -eq "True") { "with" } else { "without" }
            
            $file1 = "$SeedsDir\${envPrefix}_log_${oracleStr}_oracle_seed${seed}.txt"
            $file2 = "$SeedsDir\${envPrefix}_timestep_rewards_${oracleStr}_oracle_seed${seed}.txt"
            
            if ((Test-Path $file1) -and (Test-Path $file2)) {
                $completedCount++
            }
        }
        
        Write-Host "  [CHECK $checkCount] Completed: $completedCount/$NumSeeds seeds"
        
        if ($completedCount -eq $NumSeeds) {
            Write-Host "[SUCCESS] All $NumSeeds seeds completed!"
            break
        }
    }
    
    if ($completedCount -lt $NumSeeds) {
        Write-Host "[WARN] Not all seeds completed after $maxChecks checks"
        Write-Host "[WARN] Completed: $completedCount/$NumSeeds"
    }
    
    foreach ($batFile in $batFiles) {
        if (Test-Path $batFile) {
            Remove-Item $batFile -Force
        }
    }
}

Write-Host ""
Write-Host "=================================="
Write-Host "All experiments processing complete!"
Write-Host "=================================="

$finalFiles = Get-ChildItem $SeedsDir -Filter "*_seed*.txt"
Write-Host "Total output files: $($finalFiles.Count)"
Write-Host ""
Write-Host "Next step: Run plot_multi_seed.py to generate plots!"
