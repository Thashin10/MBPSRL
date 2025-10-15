# PSRL Replication Progress Report

**Date:** October 14, 2025  
**Goal:** Replicate Figure 1 from "Model-based Reinforcement Learning for Continuous Control with Posterior Sampling"

---

## ✅ COMPLETED

### 1. Environment Setup
- Python 3.7 conda environment `mbpsrl`
- TensorFlow 1.14.0, PyTorch 1.4.0, Gym 0.9.4
- All dependencies installed and verified

### 2. Code Modifications
- ✅ Added timestep-level logging (not just per-episode)
- ✅ Fixed Python 3.7 compatibility (f-string syntax)
- ✅ Descriptive filenames: `*_with_oracle.txt` vs `*_without_oracle.txt`
- ✅ Tracks cumulative rewards over 3000 time steps (15 episodes × 200 steps)

### 3. Experiment 1: CartPole WITH Oracle Rewards ✅
- **Status:** COMPLETE
- **Runtime:** ~11 minutes
- **Total timesteps:** 3000
- **Final cumulative reward:** 2494 (~166 per episode average)
- **Output file:** `cartpole_timestep_rewards_with_oracle.txt`
- **Expected behavior:** Fast convergence to near-optimal (~200 reward/episode)

---

## 🔄 IN PROGRESS

### 4. Experiment 2: CartPole WITHOUT Oracle Rewards (RUNNING)
- **Status:** Episode 0 complete, training in progress
- **Expected runtime:** ~10-15 minutes
- **Difference:** Learns both dynamics AND reward function
- **Expected behavior:** Slower initial learning, eventual convergence
- **Output file:** `cartpole_timestep_rewards_without_oracle.txt`

---

## 📋 QUEUED

### 5. Experiment 3: Pendulum WITH Oracle Rewards
- **Episodes:** 15 (3000 timesteps)
- **Expected reward range:** -1600 to -200 (paper Figure 1)
- **Output file:** `pendulum_timestep_rewards_with_oracle.txt`

### 6. Experiment 4: Pendulum WITHOUT Oracle Rewards
- **Episodes:** 15 (3000 timesteps)
- **Expected reward range:** -1600 to -200 (paper Figure 1)
- **Output file:** `pendulum_timestep_rewards_without_oracle.txt`

### 7. Generate Paper-Style Plots
- **Script:** `plot_paper_style.py --env both`
- **Outputs:**
  - `cartpole_paper_style.png` (overlays WITH/WITHOUT oracle)
  - `pendulum_paper_style.png` (overlays WITH/WITHOUT oracle)
  - Both PNG and SVG formats

---

## 🎯 NEXT PHASE: Baseline Comparisons

After completing the 4 PSRL experiments above, we need to run baseline algorithms for full paper replication:

### Baselines to Implement (from paper Figure 1):
1. **MBPO** (Model-Based Policy Optimization) - Green line
2. **PETS** (Probabilistic Ensembles with Trajectory Sampling) - Yellow line
3. **MPC-PSRL** (Model Predictive Control with PSRL) - Red line (our current work)

### Additional Baselines (from paper Figure 2):
4. **MB** (Model-Based)
5. **DDPG** (Deep Deterministic Policy Gradient)

**Note:** These may require additional repositories or implementations. We'll assess after PSRL results are complete.

---

## 📊 Expected Results (from Paper)

### CartPole:
- **WITH oracle (r):** Converges quickly to ~200 reward by step 1500
- **WITHOUT oracle:** Slower convergence, reaches ~150-180 by step 3000

### Pendulum:
- **WITH oracle (r):** Converges to ~-400 reward by step 2000
- **WITHOUT oracle:** Slower convergence to ~-500 to -600 by step 3000

---

## 🔧 Tools Created

1. **plot_paper_style.py** - Generates publication-quality plots matching paper format
2. **run_all_experiments.ps1** - Master orchestration script (4 experiments + plotting)
3. **check_status.ps1** - Quick status check for all experiments
4. **monitor_progress.ps1** - Real-time progress monitoring

---

## ⏱️ Estimated Timeline

- ✅ CartPole WITH oracle: **11 min** (DONE)
- 🔄 CartPole WITHOUT oracle: **~10-15 min** (IN PROGRESS)
- ⏳ Pendulum WITH oracle: **~10-15 min** (QUEUED)
- ⏳ Pendulum WITHOUT oracle: **~10-15 min** (QUEUED)
- ⏳ Generate plots: **<1 min** (QUEUED)

**Total remaining time:** ~35-50 minutes

---

## 📁 Output Files Structure

```
mbpsrl/
├── cartpole_timestep_rewards_with_oracle.txt       [3000 rows: timestep, cumulative_reward]
├── cartpole_timestep_rewards_without_oracle.txt    [3000 rows: timestep, cumulative_reward]
├── pendulum_timestep_rewards_with_oracle.txt       [3000 rows: timestep, cumulative_reward]
├── pendulum_timestep_rewards_without_oracle.txt    [3000 rows: timestep, cumulative_reward]
├── cartpole_paper_style.png                        [Comparison plot]
├── cartpole_paper_style.svg                        [Comparison plot - vector]
├── pendulum_paper_style.png                        [Comparison plot]
└── pendulum_paper_style.svg                        [Comparison plot - vector]
```

---

## 🎓 Paper Citation

Fan, Y. (Year). Model-based Reinforcement Learning for Continuous Control with Posterior Sampling.

---

*Last updated: October 14, 2025, 18:41*
