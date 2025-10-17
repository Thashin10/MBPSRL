# Manual Test Instructions

## Quick Test (5-10 minutes)

Run these commands in your terminal AFTER activating the conda environment:

```powershell
# Activate conda environment
conda activate mbpsrl

# Create test output directory
$outputDir = "test_output_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
New-Item -ItemType Directory -Path $outputDir

# Test 1: MBPO CartPole
cd baselines\mbpo
python run_mbpo_cartpole.py --seed 0 --num-episodes 2 --output-dir "..\..\$outputDir"
cd ..\..

# Test 2: MBPO Pendulum
cd baselines\mbpo
python run_mbpo_pendulum.py --seed 0 --num-episodes 2 --output-dir "..\..\$outputDir"
cd ..\..

# Test 3: PETS CartPole
cd baselines\pets
python run_pets_cartpole.py --seed 0 --num-episodes 2 --output-dir "..\..\$outputDir"
cd ..\..

# Test 4: PETS Pendulum
cd baselines\pets
python run_pets_pendulum.py --seed 0 --num-episodes 2 --output-dir "..\..\$outputDir"
cd ..\..

# Verify files were created
Get-ChildItem $outputDir
```

## Expected Output

After running all tests, you should see 8 files in the test_output directory:

1. mbpo_cartpole_log_seed0.txt
2. mbpo_cartpole_timestep_rewards_seed0.txt
3. mbpo_pendulum_log_seed0.txt
4. mbpo_pendulum_timestep_rewards_seed0.txt
5. pets_cartpole_log_seed0.txt
6. pets_cartpole_timestep_rewards_seed0.txt
7. pets_pendulum_log_seed0.txt
8. pets_pendulum_timestep_rewards_seed0.txt

## If Tests Pass

Once all 8 files are created successfully, you can run the full parallel experiments:

```powershell
# Run all 4 experiments in parallel (5 seeds each, ~6-8 hours)
powershell -ExecutionPolicy Bypass -File .\run_all_optimized_parallel.ps1
```

This will launch 4 terminal windows running:
- Terminal 1: MBPO CartPole (seeds 0-4)
- Terminal 2: MBPO Pendulum (seeds 0-4)
- Terminal 3: PETS CartPole (seeds 0-4)
- Terminal 4: PETS Pendulum (seeds 0-4)

## Monitoring Progress

Each terminal will show:
- Current seed being run
- Episode progress
- Completion time per seed

Results will be saved to: `optimized_results_YYYYMMDD_HHMMSS/`

## Expected Completion Times

- MBPO CartPole: ~2.5-3 hours (5 seeds)
- MBPO Pendulum: ~2.5-3 hours (5 seeds)
- PETS CartPole: ~2-2.5 hours (5 seeds)
- PETS Pendulum: ~2-2.5 hours (5 seeds)

**Total (running in parallel): ~6-8 hours**

## Troubleshooting

If you get "torch not found" errors:
```powershell
# Make sure you're in the conda environment
conda activate mbpsrl

# Verify torch is installed
python -c "import torch; print(torch.__version__)"
```

If you get execution policy errors:
```powershell
# Use this to bypass
powershell -ExecutionPolicy Bypass -File <script_name>.ps1
```
