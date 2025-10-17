# Quick test of Pendulum fix
$CondaExe = "C:\Users\thash\Miniconda3\Scripts\conda.exe"

Write-Host "Testing PETS Pendulum with 3 episodes..."
& $CondaExe run -n mbpsrl python -u baselines/pets/run_pets_pendulum.py --seed 0 --num-episodes 3 --num-trajs 100 --plan-hor 15 --max-iters 3

Write-Host "`nChecking if output files were created..."
if (Test-Path "seeds_data\pets_pendulum_log_seed0.txt") {
    Write-Host "[OK] pets_pendulum_log_seed0.txt created"
    Get-Content "seeds_data\pets_pendulum_log_seed0.txt"
} else {
    Write-Host "[FAIL] pets_pendulum_log_seed0.txt NOT created"
}
