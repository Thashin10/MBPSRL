# Final working version - creates batch files for each seed# run_all.ps1

param(# Orchestrate sequential runs of experiments in the mbpsrl repo using the mbpsrl conda env.

    [int]$NumSeeds = 5# Behavior:

)#  - Waits for any currently running `run_cartpole.py` process to finish.

#  - Runs CartPole, Pendulum, Reacher, Pusher (if MuJoCo available) sequentially.

Write-Host "`n========================================" -ForegroundColor Cyan#  - For each env, runs both --with-reward True and False where applicable.

Write-Host "MULTI-SEED PSRL EXPERIMENTS" -ForegroundColor Cyan#  - Saves stdout/stderr to logs/<timestamp>/env_withreward.log and env_withoutreward.log

Write-Host "========================================`n" -ForegroundColor Cyan

param(

# Clean old seed data    [string]$CondaExe = "C:\\Users\\thash\\miniconda3\\Scripts\\conda.exe",

$SeedsDir = "seeds_data"    [string]$EnvName = 'mbpsrl'

if (Test-Path $SeedsDir) {)

    Write-Host "Cleaning old seed data..." -ForegroundColor Yellow

    Remove-Item "$SeedsDir\*_seed*.txt" -Force -ErrorAction SilentlyContinuefunction Wait-ForScriptFinish($scriptName) {

    Write-Host "Old data cleaned.`n" -ForegroundColor Green    Write-Host "Waiting for any running instances of $scriptName to finish..."

} else {    while ($true) {

    New-Item -ItemType Directory -Path $SeedsDir | Out-Null        $procs = Get-WmiObject Win32_Process | Where-Object { $_.CommandLine -and $_.CommandLine -match [regex]::Escape($scriptName) }

}        if ($procs.Count -eq 0) { break }

        Write-Host "Detected $($procs.Count) running process(es) for $scriptName. Sleeping 30s..."

$CondaExe = "C:\Users\thash\Miniconda3\Scripts\conda.exe"        Start-Sleep -Seconds 30

    }

# Experiments    Write-Host "$scriptName no longer running. Proceeding."

$experiments = @(}

    @{Name="CartPole-WithOracle"; Script="run_cartpole.py"; WithReward="True"},

    @{Name="CartPole-WithoutOracle"; Script="run_cartpole.py"; WithReward="False"},# create logs dir

    @{Name="Pendulum-WithOracle"; Script="run_pendulum.py"; WithReward="True"},$ts = Get-Date -Format "yyyyMMdd_HHmmss"

    @{Name="Pendulum-WithoutOracle"; Script="run_pendulum.py"; WithReward="False"}$logdir = Join-Path -Path (Get-Location) -ChildPath ("logs_$ts")

)New-Item -ItemType Directory -Path $logdir | Out-Null



$totalStart = Get-Date# wait for existing cartpole run to finish

Wait-ForScriptFinish 'run_cartpole.py'

for ($expNum = 0; $expNum -lt $experiments.Count; $expNum++) {

    $exp = $experiments[$expNum]# helper to run a single experiment and redirect output

    function Run-Experiment($scriptPath, $withReward) {

    Write-Host "========================================" -ForegroundColor Cyan    $rewardStr = if ($withReward) { 'True' } else { 'False' }

    Write-Host "[$(($expNum+1))/4] $($exp.Name)" -ForegroundColor Cyan    $name = [System.IO.Path]::GetFileNameWithoutExtension($scriptPath)

    Write-Host "========================================`n" -ForegroundColor Cyan    $suffix = if ($withReward) { 'with_reward' } else { 'without_reward' }

        $outfile = Join-Path $logdir "${name}_${suffix}.log"

    $expStart = Get-Date

    $batFiles = @()    Write-Host "Running: $scriptPath --with-reward $rewardStr -> $outfile"

        # Pass arguments as separate tokens so PowerShell doesn't treat them as a single string

    # Create and launch batch files for each seed    $args = @($scriptPath, '--with-reward', $rewardStr)

    Write-Host "Starting $NumSeeds seeds in parallel...`n" -ForegroundColor Yellow    & $CondaExe run -n $EnvName python @args *>&1 | Tee-Object -FilePath $outfile

    }

    for ($seed = 0; $seed -lt $NumSeeds; $seed++) {

        $batFile = "run_seed${seed}.bat"# experiments to run (scripts relative to repo root)

        $logFile = "log_seed${seed}.txt"$repoRoot = (Get-Location).Path

        $batFiles += $batFile$cartpole = Join-Path $repoRoot 'run_cartpole.py'

        $pendulum = Join-Path $repoRoot 'run_pendulum.py'

        # Create batch file with the command$reacher = Join-Path $repoRoot 'run_reacher.py'

        $batContent = @"$pusher = Join-Path $repoRoot 'run_pusher.py'

@echo off

cd /d "$($PWD.Path)"# Run CartPole (if it hasn't been run already in this session)

"$CondaExe" run -n mbpsrl python $($exp.Script) --with-reward $($exp.WithReward) --seed $seed --num-episodes 15 > $logFile 2>&1Run-Experiment $cartpole $true

"@Run-Experiment $cartpole $false

        Set-Content -Path $batFile -Value $batContent

        # Pendulum

        # Launch itRun-Experiment $pendulum $true

        Start-Process -FilePath $batFile -WindowStyle HiddenRun-Experiment $pendulum $false

        Write-Host "  Seed $seed launched" -ForegroundColor Gray

        # Reacher

        Start-Sleep -Milliseconds 200Run-Experiment $reacher $true

    }Run-Experiment $reacher $false

    

    Write-Host "`nWaiting for completion (checking every 20 seconds)...`n" -ForegroundColor Yellow# Pusher (only if mujoco-py importable)

    $mujocoOK = $false

    # Monitor for completiontry {

    $completed = @()    & $CondaExe run -n $EnvName python -c "import mujoco_py" 2>$null

    $maxChecks = 100  # Max ~33 minutes per experiment    if ($LASTEXITCODE -eq 0) { $mujocoOK = $true }

    $checkNum = 0} catch {

        $mujocoOK = $false

    while ($completed.Count -lt $NumSeeds -and $checkNum -lt $maxChecks) {}

        Start-Sleep -Seconds 20

        $checkNum++if ($mujocoOK) {

            Run-Experiment $pusher $true

        $newCompleted = @()    Run-Experiment $pusher $false

        for ($seed = 0; $seed -lt $NumSeeds; $seed++) {} else {

            if ($seed -in $completed) {    Write-Host "Skipping Pusher runs: mujoco_py not available in env 'mbpsrl'." | Tee-Object -FilePath (Join-Path $logdir 'pusher_skipped.txt')

                $newCompleted += $seed}

                continue

            }Write-Host "All scheduled experiments finished (or skipped). Logs are in: $logdir"

            
            # Check for output files
            $files = Get-ChildItem $SeedsDir -Filter "*_seed${seed}.txt" -ErrorAction SilentlyContinue
            
            if ($files.Count -ge 2) {
                $newCompleted += $seed
                Write-Host "  [COMPLETE] Seed $seed finished ($($newCompleted.Count)/$NumSeeds)" -ForegroundColor Green
            }
        }
        
        $completed = $newCompleted
        
        if ($completed.Count -lt $NumSeeds) {
            $elapsed = [math]::Round(((Get-Date) - $expStart).TotalMinutes, 1)
            $remaining = $NumSeeds - $completed.Count
            Write-Host "  [PROGRESS] $($completed.Count)/$NumSeeds done, $remaining remaining | ${elapsed} min | Check #$checkNum" -ForegroundColor Gray
        }
    }
    
    # Clean up
    foreach ($bat in $batFiles) {
        Remove-Item $bat -ErrorAction SilentlyContinue
    }
    Remove-Item "log_seed*.txt" -ErrorAction SilentlyContinue
    
    $expTime = [math]::Round(((Get-Date) - $expStart).TotalMinutes, 1)
    Write-Host "`n  EXPERIMENT DONE in $expTime minutes!`n" -ForegroundColor Green
}

$totalTime = [math]::Round(((Get-Date) - $totalStart).TotalMinutes, 1)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "ALL COMPLETE!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Total time: $totalTime minutes`n" -ForegroundColor Yellow

# Verify
$allFiles = Get-ChildItem $SeedsDir -Filter "*_seed*.txt"
$expected = $NumSeeds * 4 * 2

if ($allFiles.Count -eq $expected) {
    Write-Host "SUCCESS! All $($allFiles.Count) files created." -ForegroundColor Green
    Write-Host "`nNext:" -ForegroundColor Cyan
    Write-Host "  & `"$CondaExe`" run -n mbpsrl python plot_multi_seed.py --env both --num-seeds $NumSeeds" -ForegroundColor White
} else {
    Write-Host "WARNING: Expected $expected, got $($allFiles.Count) files" -ForegroundColor Yellow
}
