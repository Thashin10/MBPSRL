# Staged Execution Guide - Run Experiments in ~2 Hour Chunks

You can run all experiments in 4 stages, each taking approximately 1.5-2 hours. This allows you to pause between stages and continue later.

---

## 📋 Overview

| Stage | Experiment | Time | Files Created |
|-------|-----------|------|---------------|
| 1 | MBPO CartPole (5 seeds) | ~1.5-2 hrs | 10 files |
| 2 | MBPO Pendulum (5 seeds) | ~1.5-2 hrs | 10 files |
| 3 | PETS CartPole (5 seeds) | ~1.5-2 hrs | 10 files |
| 4 | PETS Pendulum (5 seeds) | ~1.5-2 hrs | 10 files |
| **TOTAL** | **All experiments** | **6-8 hrs** | **40 files** |

---

## 🚀 Stage 1: MBPO CartPole (~2 hours)

Double-click or run:
```bash
.\run_mbpo_cartpole_all_seeds.bat
```

**What it does:**
- Runs MBPO on CartPole for seeds 0-4
- 15 episodes per seed
- Creates `optimized_results_<timestamp>` directory
- Shows progress for each seed

**Output files:**
- `mbpo_cartpole_log_seed0.txt` through `seed4.txt`
- `mbpo_cartpole_timestep_rewards_seed0.txt` through `seed4.txt`

**When done:** Note the output directory name (e.g., `optimized_results_20251017_140000`). You'll need it for the next stages!

---

## 🚀 Stage 2: MBPO Pendulum (~2 hours)

**IMPORTANT:** Use the same output directory from Stage 1!

```bash
.\run_mbpo_pendulum_all_seeds.bat optimized_results_20251017_140000
```

Replace `optimized_results_20251017_140000` with YOUR output directory from Stage 1.

**Output files:**
- `mbpo_pendulum_log_seed0.txt` through `seed4.txt`
- `mbpo_pendulum_timestep_rewards_seed0.txt` through `seed4.txt`

Total files so far: 20

---

## 🚀 Stage 3: PETS CartPole (~2 hours)

```bash
.\run_pets_cartpole_all_seeds.bat optimized_results_20251017_140000
```

**Output files:**
- `pets_cartpole_log_seed0.txt` through `seed4.txt`
- `pets_cartpole_timestep_rewards_seed0.txt` through `seed4.txt`

Total files so far: 30

---

## 🚀 Stage 4: PETS Pendulum (~2 hours)

```bash
.\run_pets_pendulum_all_seeds.bat optimized_results_20251017_140000
```

**Output files:**
- `pets_pendulum_log_seed0.txt` through `seed4.txt`
- `pets_pendulum_timestep_rewards_seed0.txt` through `seed4.txt`

**Total files: 40 ✅**

---

## ⏸️ Pausing and Resuming

### To Pause:
- **Between stages:** Simply close the window after a stage completes, or press any key when it says "Press any key to continue..."
- **During a stage:** Press `Ctrl+C` - the current seed will finish, then it will stop

### To Resume:
- Run the next stage script
- **CRITICAL:** Always pass the same output directory name to keep all results together!

Example resuming at Stage 3:
```bash
.\run_pets_cartpole_all_seeds.bat optimized_results_20251017_140000
```

---

## 🎯 Quick Start (Just Getting Started Now)

1. Open Command Prompt or PowerShell
2. Navigate to your project directory:
   ```bash
   cd "C:\Users\thash\OneDrive\Documents\Analytics\Honours\Research Project\RL elective\PSRL\mbpsrl"
   ```
3. Run Stage 1:
   ```bash
   .\run_mbpo_cartpole_all_seeds.bat
   ```
4. Wait ~2 hours or until complete
5. **Write down the output directory name!**
6. When ready, run Stage 2 with that directory name

---

## 🔄 Alternative: Run All at Once

### Option A: Sequential (One After Another, 6-8 hours)

Create a master batch file or run manually:

```bash
set OUTPUT_DIR=optimized_results_final
mkdir %OUTPUT_DIR%

call .\run_mbpo_cartpole_all_seeds.bat %OUTPUT_DIR%
call .\run_mbpo_pendulum_all_seeds.bat %OUTPUT_DIR%
call .\run_pets_cartpole_all_seeds.bat %OUTPUT_DIR%
call .\run_pets_pendulum_all_seeds.bat %OUTPUT_DIR%
```

### Option B: Parallel (4 Terminals, ~2-2.5 hours)

Open 4 separate terminals and run simultaneously:

**Terminal 1:**
```bash
.\run_mbpo_cartpole_all_seeds.bat parallel_run
```

**Terminal 2:**
```bash
.\run_mbpo_pendulum_all_seeds.bat parallel_run
```

**Terminal 3:**
```bash
.\run_pets_cartpole_all_seeds.bat parallel_run
```

**Terminal 4:**
```bash
.\run_pets_pendulum_all_seeds.bat parallel_run
```

---

## ✅ Verifying Progress

Check your output directory at any time:

```bash
dir optimized_results_20251017_140000
```

**Expected files after each stage:**
- After Stage 1: 10 files (mbpo_cartpole_*)
- After Stage 2: 20 files (+ mbpo_pendulum_*)
- After Stage 3: 30 files (+ pets_cartpole_*)
- After Stage 4: 40 files (+ pets_pendulum_*)

---

## 📊 What You'll See During Execution

Each seed shows:
```
========================================
Running MBPO CartPole - Seed 2 / 4
========================================
Start time: 14:30:45

Episode   0: Reward = 18.03, Length = 18
Episode   1: Reward = 29.96, Length = 30
...
Episode  14: Reward = 145.23, Length = 145

Seed 2 completed at 15:05:12
```

---

## 🛠️ Troubleshooting

**Problem: "Cannot find conda environment"**
- The batch files automatically activate conda
- If it still fails, your Miniconda path might be different
- Edit the batch file and check line: `call C:\Users\thash\Miniconda3\Scripts\activate.bat mbpsrl`

**Problem: "No module named 'torch'"**
- Run: `.\install_pytorch.bat`
- This installs PyTorch 1.7.1 (already done if test worked)

**Problem: Files not being created**
- Check terminal output for errors
- Verify the output directory exists
- Make sure previous seeds completed successfully

**Problem: Want to stop mid-stage**
- Press `Ctrl+C`
- Current seed will complete, then stop
- To resume, you'll need to manually edit the batch file to start from the next seed

---

## 💡 Recommendations

**Best approach for pausable execution:**
1. Run Stage 1 before a 2-hour session
2. Take a break (close terminal)
3. Run Stage 2 in next session
4. Repeat for Stages 3 and 4

**Best approach for fastest completion:**
- Run Option B (Parallel) if your computer can handle it
- All 4 experiments run simultaneously
- Done in ~2-2.5 hours

**Best approach for overnight:**
- Run Option A (Sequential)
- Let it run overnight or while you're away
- Done in 6-8 hours, all automatically

---

## 📁 Output Directory Structure

After all stages complete:

```
optimized_results_20251017_140000/
├── mbpo_cartpole_log_seed0.txt
├── mbpo_cartpole_log_seed1.txt
├── mbpo_cartpole_log_seed2.txt
├── mbpo_cartpole_log_seed3.txt
├── mbpo_cartpole_log_seed4.txt
├── mbpo_cartpole_timestep_rewards_seed0.txt
├── mbpo_cartpole_timestep_rewards_seed1.txt
├── mbpo_cartpole_timestep_rewards_seed2.txt
├── mbpo_cartpole_timestep_rewards_seed3.txt
├── mbpo_cartpole_timestep_rewards_seed4.txt
├── (same pattern for mbpo_pendulum_*)
├── (same pattern for pets_cartpole_*)
└── (same pattern for pets_pendulum_*)
```

40 files total!

---

## 🎉 What's Next?

After all experiments complete, you'll:
1. Generate comparison plots (PSRL vs MBPO vs PETS)
2. Analyze learning curves
3. Create publication-quality figures

Let me know when you're done and I'll help with the plotting! 📈
