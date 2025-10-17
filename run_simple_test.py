# Simple test script - run this AFTER activating conda environment
# Usage: 
#   conda activate mbpsrl
#   python run_simple_test.py

import os
import subprocess
import time
from datetime import datetime

print("="*60)
print("Simple Test: All Optimized Baselines")
print("="*60)
print()

# Create test output directory
timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
output_dir = "test_output_{}".format(timestamp)
os.makedirs(output_dir, exist_ok=True)
print("Test results will be saved to: {}".format(output_dir))
print()

tests = [
    ("MBPO CartPole", "baselines/mbpo", "python run_mbpo_cartpole.py --seed 0 --num-episodes 2 --output-dir ../../{}".format(output_dir)),
    ("MBPO Pendulum", "baselines/mbpo", "python run_mbpo_pendulum.py --seed 0 --num-episodes 2 --output-dir ../../{}".format(output_dir)),
    ("PETS CartPole", "baselines/pets", "python run_pets_cartpole.py --seed 0 --num-episodes 2 --output-dir ../../{}".format(output_dir)),
    ("PETS Pendulum", "baselines/pets", "python run_pets_pendulum.py --seed 0 --num-episodes 2 --output-dir ../../{}".format(output_dir)),
]

# Run tests
for i, (name, directory, command) in enumerate(tests, 1):
    print("[{}/4] Testing {}...".format(i, name))
    start_time = time.time()
    
    # Change to the correct directory
    original_dir = os.getcwd()
    os.chdir(directory)
    
    # Run the test
    result = subprocess.run(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)
    
    # Return to original directory
    os.chdir(original_dir)
    
    elapsed = time.time() - start_time
    print("  Completed in: {:02d}:{:02d}".format(int(elapsed//60), int(elapsed%60)))
    
    if result.returncode != 0:
        print("  ERROR: {} failed!".format(name))
        print("  {}".format(result.stderr[:200]))
    print()

# Verify output files
print("="*60)
print("Verification: Checking Output Files")
print("="*60)
print()

expected_files = [
    "mbpo_cartpole_log_seed0.txt",
    "mbpo_cartpole_timestep_rewards_seed0.txt",
    "mbpo_pendulum_log_seed0.txt",
    "mbpo_pendulum_timestep_rewards_seed0.txt",
    "pets_cartpole_log_seed0.txt",
    "pets_cartpole_timestep_rewards_seed0.txt",
    "pets_pendulum_log_seed0.txt",
    "pets_pendulum_timestep_rewards_seed0.txt"
]

all_good = True
for filename in expected_files:
    filepath = os.path.join(output_dir, filename)
    if os.path.exists(filepath):
        size_kb = round(os.path.getsize(filepath) / 1024, 2)
        print("  [OK] {} ({} KB)".format(filename, size_kb))
    else:
        print("  [MISSING] {}".format(filename))
        all_good = False

print()
if all_good:
    print("="*60)
    print("SUCCESS: All tests passed!")
    print("="*60)
    print()
    print("All 8 files created successfully.")
    print("The parallel script should work correctly.")
else:
    print("="*60)
    print("WARNING: Some files missing")
    print("="*60)
    print()
    print("Check the error messages above.")

print()
print("Output directory: {}".format(output_dir))
print()
