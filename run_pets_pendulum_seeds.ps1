# Run PETS Pendulum for both seeds
$CondaExe = "C:\Users\thash\Miniconda3\Scripts\conda.exe"

Write-Host "=========================================="
Write-Host "PETS Pendulum - Seeds 0 and 1"
Write-Host "=========================================="

for ($seed = 0; $seed -lt 2; $seed++) {
    Write-Host "`nSeed $seed - Starting..."
    
    & $CondaExe run -n mbpsrl python -u baselines/pets/run_pets_pendulum.py `
        --seed $seed `
        --num-episodes 15 `
        --num-trajs 100 `
        --plan-hor 15 `
        --max-iters 3
    
    Write-Host "Seed $seed completed"
}

Write-Host "`n=========================================="
Write-Host "Verifying Pendulum files..."
Write-Host "=========================================="

if (Test-Path "seeds_data\pets_pendulum_log_seed0.txt") {
    $lines = (Get-Content "seeds_data\pets_pendulum_log_seed0.txt" | Measure-Object -Line).Lines
    Write-Host "[OK] pets_pendulum_log_seed0.txt ($lines episodes)"
} else {
    Write-Host "[MISSING] pets_pendulum_log_seed0.txt"
}

if (Test-Path "seeds_data\pets_pendulum_log_seed1.txt") {
    $lines = (Get-Content "seeds_data\pets_pendulum_log_seed1.txt" | Measure-Object -Line).Lines
    Write-Host "[OK] pets_pendulum_log_seed1.txt ($lines episodes)"
} else {
    Write-Host "[MISSING] pets_pendulum_log_seed1.txt"
}
