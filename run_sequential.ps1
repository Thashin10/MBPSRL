param(
    [string]$Experiment = "cartpole_with",
    [int]$NumSeeds = 5
)

$ErrorActionPreference = "Continue"

$CondaExe = "C:\Users\thash\Miniconda3\Scripts\conda.exe"

# Experiment configurations
$configs = @{
    "cartpole_with" = @{Name="CartPole WITH Oracle"; Script="run_cartpole.py"; WithReward="True"}
    "cartpole_without" = @{Name="CartPole WITHOUT Oracle"; Script="run_cartpole.py"; WithReward="False"}
    "pendulum_with" = @{Name="Pendulum WITH Oracle"; Script="run_pendulum.py"; WithReward="True"}
    "pendulum_without" = @{Name="Pendulum WITHOUT Oracle"; Script="run_pendulum.py"; WithReward="False"}
}

$config = $configs[$Experiment]

Write-Host "=========================================="
Write-Host "Running: $($config.Name)"
Write-Host "Seeds: 0 to $($NumSeeds - 1) (SEQUENTIAL)"
Write-Host "=========================================="
Write-Host "Estimated time: $($NumSeeds * 15) minutes (~15 min per seed)"
Write-Host ""

$startTime = Get-Date

for ($seed = 0; $seed -lt $NumSeeds; $seed++) {
    $seedStart = Get-Date
    
    Write-Host "=========================================="
    Write-Host "Seed $seed / $($NumSeeds - 1)"
    Write-Host "=========================================="
    
    & $CondaExe run -n mbpsrl python $($config.Script) --with-reward $($config.WithReward) --seed $seed --num-episodes 15
    
    $seedElapsed = [math]::Round(((Get-Date) - $seedStart).TotalMinutes, 1)
    $totalElapsed = [math]::Round(((Get-Date) - $startTime).TotalMinutes, 1)
    
    Write-Host ""
    Write-Host "[COMPLETE] Seed $seed finished in ${seedElapsed} minutes"
    Write-Host "[PROGRESS] Total elapsed: ${totalElapsed} minutes"
    Write-Host ""
    
    # Verify output
    $envPrefix = if ($config.Script -like "*cartpole*") { "cartpole" } else { "pendulum" }
    $oracleStr = if ($config.WithReward -eq "True") { "with" } else { "without" }
    $file = "seeds_data\${envPrefix}_timestep_rewards_${oracleStr}_oracle_seed${seed}.txt"
    
    if (Test-Path $file) {
        $lines = (Get-Content $file).Count
        Write-Host "[VERIFY] Seed $seed : $lines timesteps"
    } else {
        Write-Host "[ERROR] Seed $seed : Output file not found!"
    }
    Write-Host ""
}

$totalTime = [math]::Round(((Get-Date) - $startTime).TotalMinutes, 1)

Write-Host "=========================================="
Write-Host "EXPERIMENT COMPLETE!"
Write-Host "=========================================="
Write-Host "Total time: ${totalTime} minutes"
Write-Host ""
Write-Host "Results:"
for ($seed = 0; $seed -lt $NumSeeds; $seed++) {
    $envPrefix = if ($config.Script -like "*cartpole*") { "cartpole" } else { "pendulum" }
    $oracleStr = if ($config.WithReward -eq "True") { "with" } else { "without" }
    $file = "seeds_data\${envPrefix}_timestep_rewards_${oracleStr}_oracle_seed${seed}.txt"
    
    if (Test-Path $file) {
        $lines = (Get-Content $file).Count
        Write-Host "  Seed $seed : $lines timesteps"
    }
}
