# Environment and Execution Guide

## Complete Environment Specifications

### Python Environment
- **Python Version**: 3.7.1
- **Environment Type**: Conda/Miniconda3
- **Environment Name**: `mbpsrl`
- **Location**: `C:\Users\thash\Miniconda3\envs\mbpsrl`

### Required Python Packages

#### Core Dependencies
- **TensorFlow**: 1.14.0 (for PSRL and PETS dynamics models)
- **PyTorch**: 1.7.1+cpu (for MBPO policy networks)
- **torchvision**: 0.8.2+cpu
- **NumPy**: 1.16.5
- **SciPy**: 1.3.1
- **Gym**: 0.14.0 (OpenAI Gym for environments)
- **Pillow**: 9.5.0

#### Additional Packages
- matplotlib (for plotting)
- pandas (for data processing)
- scikit-learn (for analysis)

### Installation Instructions

#### 1. Create Conda Environment
```bash
conda create -n mbpsrl python=3.7.1
conda activate mbpsrl
```

#### 2. Install TensorFlow
```bash
pip install tensorflow==1.14.0
```

#### 3. Install PyTorch (CPU version)
```bash
pip install torch==1.7.1+cpu torchvision==0.8.2+cpu -f https://download.pytorch.org/whl/torch_stable.html
```

Or use the provided batch file:
```batch
.\install_pytorch.bat
```

#### 4. Install Other Dependencies
```bash
pip install numpy==1.16.5 scipy==1.3.1 gym==0.14.0 pillow==9.5.0 matplotlib pandas scikit-learn
```

Or use the requirements file:
```bash
pip install -r pip-requirements.txt
```

### Environment Verification

To verify your environment is correctly configured:

```powershell
# Activate environment
conda activate mbpsrl

# Check Python version
python --version
# Expected: Python 3.7.1

# Check TensorFlow
python -c "import tensorflow as tf; print('TensorFlow:', tf.__version__)"
# Expected: TensorFlow: 1.14.0

# Check PyTorch
python -c "import torch; print('PyTorch:', torch.__version__)"
# Expected: PyTorch: 1.7.1+cpu

# Check NumPy
python -c "import numpy as np; print('NumPy:', np.__version__)"
# Expected: NumPy: 1.16.5
```

---

## Running MBPO Experiments

### MBPO Architecture
- **Algorithm**: Simplified Model-Based Policy Optimization
- **Policy Network**: Actor-Critic architecture (not full SAC for efficiency)
- **Actor Network**: [256, 256] hidden layers with tanh output
- **Critic Network**: [256, 256] hidden layers
- **Replay Buffer**: 10,000 capacity
- **Model Rollouts**: 400 trajectories × 5 steps per update
- **Policy Updates**: 40 updates per episode (optimized from 20)

### MBPO Optimizations Applied
1. **Xavier Initialization**: Weights initialized with `gain=0.5` for stable learning
2. **Oracle Reward Functions**: Environment-specific reward estimation
   - CartPole: `cos(θ) - 0.01*x² + 0.1*exp(-|θ|)` (uprightness + stability)
   - Pendulum: `-(θ² + 0.1*θ_dot² + 0.001*u²)` (minimize angle/velocity)
3. **Increased Policy Updates**: 40 updates per episode (was 20)

### Running MBPO Batch Experiments

#### Stage 1: MBPO CartPole (5 seeds, ~2 hours)
```batch
.\run_mbpo_cartpole_all_seeds.bat
```

This creates a timestamped output directory (e.g., `optimized_results_20241017_140530`) and runs:
- Seeds 0-4 sequentially
- 15 episodes per seed
- Output files per seed:
  - `mbpo_cartpole_log_seed{N}.txt` (episode summaries)
  - `mbpo_cartpole_timestep_rewards_seed{N}.txt` (detailed timestep data)

**Expected Performance**: 90-120 average reward (improvement from ~50 baseline)

#### Stage 2: MBPO Pendulum (5 seeds, ~2 hours)
```batch
.\run_mbpo_pendulum_all_seeds.bat optimized_results_20241017_140530
```

**IMPORTANT**: Use the same output directory name from Stage 1!

This runs:
- Seeds 0-4 sequentially
- 15 episodes per seed
- Adds 10 more files to the same directory

**Expected Performance**: -400 to -500 average reward

### MBPO Single Seed Test
To quickly test MBPO is working (2 episodes, ~2 minutes):
```batch
.\test_mbpo_cartpole.bat
```

Expected output:
```
Episode 0: Reward = 18-20, Length = 18-20
Episode 1: Reward = 28-32, Length = 28-32
```

---

## Running PETS Experiments

### PETS Architecture
- **Algorithm**: Probabilistic Ensembles with Trajectory Sampling
- **Ensemble Size**: 5 neural networks
- **Dynamics Model**: Fully connected networks predicting next state
- **Planning**: Cross-Entropy Method (CEM) optimization
- **Trajectory Sampling**: TS (sampling from ensemble)

### PETS Parameters
**Optimized Parameters** (current configuration):
- **K**: 100 (candidate sequences per iteration)
- **H**: 15 (planning horizon)
- **I**: 3 (CEM iterations)
- **Episodes**: 15
- **Target Timesteps**: ~3000

**Paper Parameters** (original, much slower):
- K: 500
- H: 30
- I: 5

We use reduced parameters for ~10x speedup with reasonable performance.

### PETS Optimizations Applied
1. **Better CEM Warm-Start**: Repeat last action instead of zeros for initial mean
   ```python
   # Before: np.zeros(action_shape)
   # After: self.pre_means[-action_shape:]
   ```
2. **CartPole Reward Shaping**: Added stability bonus `0.1*exp(-|θ|)`

### Running PETS Batch Experiments

#### Stage 3: PETS CartPole (5 seeds, ~2 hours)
```batch
.\run_pets_cartpole_all_seeds.bat optimized_results_20241017_140530
```

**IMPORTANT**: Use the same output directory name from Stages 1-2!

This runs:
- Seeds 0-4 sequentially
- 15 episodes per seed
- Output files per seed:
  - `pets_cartpole_log_seed{N}.txt` (episode summaries)
  - `pets_cartpole_timestep_rewards_seed{N}.txt` (detailed timestep data)

**Expected Performance**: 42-50 average reward (improvement from 28)

#### Stage 4: PETS Pendulum (5 seeds, ~2 hours)
```batch
.\run_pets_pendulum_all_seeds.bat optimized_results_20241017_140530
```

**IMPORTANT**: Use the same output directory name from Stages 1-3!

This runs:
- Seeds 0-4 sequentially
- 15 episodes per seed
- Completes the full experiment suite

**Expected Performance**: -1200 to -1400 average reward (improvement from -1768)

---

## Complete Execution Workflow

### Sequential Execution (Recommended for Pausable Control)

**Total Time**: 6-8 hours (can pause between stages)

1. **Stage 1** (~2 hours):
   ```batch
   .\run_mbpo_cartpole_all_seeds.bat
   ```
   Note the output directory name (e.g., `optimized_results_20241017_140530`)

2. **Stage 2** (~2 hours):
   ```batch
   .\run_mbpo_pendulum_all_seeds.bat optimized_results_20241017_140530
   ```

3. **PAUSE POINT**: You can stop here and resume later

4. **Stage 3** (~2 hours):
   ```batch
   .\run_pets_cartpole_all_seeds.bat optimized_results_20241017_140530
   ```

5. **PAUSE POINT**: You can stop here and resume later

6. **Stage 4** (~2 hours):
   ```batch
   .\run_pets_pendulum_all_seeds.bat optimized_results_20241017_140530
   ```

### Parallel Execution (Faster but No Pausing)

**Total Time**: 2-2.5 hours (all at once)

1. Create output directory manually:
   ```batch
   mkdir optimized_results_parallel
   ```

2. Open 4 PowerShell terminals and run simultaneously:
   - Terminal 1: `.\run_mbpo_cartpole_all_seeds.bat optimized_results_parallel`
   - Terminal 2: `.\run_mbpo_pendulum_all_seeds.bat optimized_results_parallel`
   - Terminal 3: `.\run_pets_cartpole_all_seeds.bat optimized_results_parallel`
   - Terminal 4: `.\run_pets_pendulum_all_seeds.bat optimized_results_parallel`

---

## Output Files Structure

After completing all 4 stages, your output directory should contain **40 files**:

```
optimized_results_<timestamp>/
├── MBPO CartPole (10 files):
│   ├── mbpo_cartpole_log_seed0.txt
│   ├── mbpo_cartpole_timestep_rewards_seed0.txt
│   ├── mbpo_cartpole_log_seed1.txt
│   ├── mbpo_cartpole_timestep_rewards_seed1.txt
│   ├── ... (seeds 2-4)
│
├── MBPO Pendulum (10 files):
│   ├── mbpo_pendulum_log_seed0.txt
│   ├── mbpo_pendulum_timestep_rewards_seed0.txt
│   ├── ... (seeds 1-4)
│
├── PETS CartPole (10 files):
│   ├── pets_cartpole_log_seed0.txt
│   ├── pets_cartpole_timestep_rewards_seed0.txt
│   ├── ... (seeds 1-4)
│
└── PETS Pendulum (10 files):
    ├── pets_pendulum_log_seed0.txt
    ├── pets_pendulum_timestep_rewards_seed0.txt
    └── ... (seeds 1-4)
```

### Verification Command
```batch
dir optimized_results_<timestamp> | find /c ".txt"
```
Expected output: `40` files

---

## Batch File Details

### Batch File Structure

Each batch file follows this pattern:

```batch
@echo off
setlocal enabledelayedexpansion

REM Activate conda environment
call C:\Users\thash\Miniconda3\Scripts\activate.bat mbpsrl

REM Create or use existing output directory
if "%~1"=="" (
    set output_dir=optimized_results_%date:~-4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%%time:~6,2%
    mkdir !output_dir!
) else (
    set output_dir=%~1
)

echo Output directory: !output_dir!
echo Starting [Experiment] - 5 seeds
echo.

REM Run all seeds sequentially
for /l %%s in (0,1,4) do (
    echo ==========================================
    echo Running [Experiment] - Seed %%s / 4
    echo Start time: !time!
    echo ==========================================
    
    python baselines\[path]\run_[experiment].py --seed %%s --num-episodes 15 --output-dir !output_dir!
    
    echo Completed Seed %%s at !time!
    echo.
)

echo ==========================================
echo All seeds completed!
echo Results saved to: !output_dir!
echo ==========================================
pause
```

### Key Features
1. **Automatic Conda Activation**: No manual activation needed
2. **Timestamped Directories**: Automatic directory creation for Stage 1
3. **Shared Directory Support**: Pass directory name for Stages 2-4
4. **Progress Tracking**: Timestamps per seed
5. **Pause on Completion**: View results before closing window

---

## Troubleshooting

### Issue: "conda not recognized"
**Solution**: Use the batch files (.bat) instead of PowerShell scripts. Batch files properly activate conda.

### Issue: "No module named 'torch'"
**Solution**: Run `.\install_pytorch.bat` to install PyTorch 1.7.1+cpu

### Issue: Python syntax errors in PETS scripts
**Solution**: Code already fixed for Python 3.7.1 compatibility (removed `flush=True`, fixed f-strings)

### Issue: Batch file won't run
**Solution**: 
1. Right-click the .bat file
2. Select "Run as administrator" if needed
3. Or open PowerShell and run: `cmd /c .\[filename].bat`

### Issue: Output directory not found
**Solution**: For Stages 2-4, ensure you pass the exact directory name from Stage 1

### Issue: Experiments taking too long
**Current configuration**: PETS uses reduced parameters (100/15/3) for ~10x speedup
- If still too slow, reduce episodes: `--num-episodes 10` (instead of 15)
- Or reduce seeds: only run seeds 0-2 instead of 0-4

---

## Expected Performance Improvements

### MBPO (vs baseline ~50 reward)
- **CartPole**: 90-120 reward (+80-100% improvement)
- **Pendulum**: -400 to -500 reward
- **Time Cost**: +20% per run (40 updates vs 20)

### PETS (vs baseline 28 CartPole, -1768 Pendulum)
- **CartPole**: 42-50 reward (+50-70% improvement)
- **Pendulum**: -1200 to -1400 reward (+20-30% improvement)
- **Time Cost**: 0% (optimizations don't add time)

---

## Repository Information

- **GitHub Repository**: https://github.com/Thashin10/MBPSRL
- **Current Branch**: master
- **Last Commit**: 47df9eb - "Add optimized MBPO and PETS baselines with staged execution system"

### Files to Review
- `OPTIMIZATIONS_APPLIED.md` - Technical details of all optimizations
- `STAGED_EXECUTION_GUIDE.md` - Detailed usage instructions
- `MBPO_IMPLEMENTATION_SUMMARY.md` - MBPO architecture details
- `PETS_VERIFICATION_RESULTS.md` - PETS performance analysis

---

## Citation

If using this code, please cite the original papers:

**PSRL**:
```
Osband, I., Blundell, C., Pritzel, A., & Van Roy, B. (2016).
Deep exploration via bootstrapped DQN. NIPS.
```

**PETS**:
```
Chua, K., Calandra, R., McAllister, R., & Levine, S. (2018).
Deep reinforcement learning in a handful of trials using probabilistic dynamics models. NIPS.
```

**MBPO**:
```
Janner, M., Fu, J., Zhang, M., & Levine, S. (2019).
When to trust your model: Model-based policy optimization. NeurIPS.
```

---

## Contact

For issues or questions:
1. Check the troubleshooting section above
2. Review the detailed guides in the repository
3. Open an issue on GitHub: https://github.com/Thashin10/MBPSRL/issues
