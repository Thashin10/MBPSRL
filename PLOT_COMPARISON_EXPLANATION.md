# Understanding the Two Types of Learning Curve Plots

## Summary of Results

We have generated two types of plots to analyze the performance of PSRL vs PETS:

### 1. **Episode-Based Learning Curves** (✓ RECOMMENDED)
**Files:** `cartpole_learning_curves.png`, `pendulum_learning_curves.png`

**What it shows:**
- X-axis: Episode number (0-14)
- Y-axis: Average reward per episode
- Comparison: All three algorithms (PSRL with/without oracle, PETS)

**Why it's better:**
- Shows true learning progression
- Directly measures how well the agent performs in each episode
- Not confounded by number of episodes run

**Results at Episode 14:**

**CartPole:**
- PSRL (with oracle): **197.4 ± 2.2** ✓ Near-optimal (max is 200)
- PSRL (without oracle): **158.0 ± 15.2** ✓ Good performance
- PETS: **23.2 ± 1.5** ✗ Poor performance (stays low)

**Pendulum:**
- PSRL (with oracle): **-359.3 ± 1.8** ✓ Best (less negative)
- PSRL (without oracle): **-379.6 ± 17.8** ✓ Good
- PETS: **-1770.8 ± 12.2** ✗ Much worse

**Interpretation:** PSRL learns to achieve high rewards quickly (by episode 4-5 for CartPole), while PETS never learns to balance well.

---

### 2. **Timestep-Based Cumulative Rewards** (⚠️ MISLEADING for comparison)
**Files:** `cartpole_timestep_comparison.png`, `pendulum_timestep_comparison.png`

**What it shows:**
- X-axis: Timestep (0-3000)
- Y-axis: Cumulative reward (sum of all rewards up to that timestep)
- Comparison: All three algorithms

**Why it's misleading:**
- Rewards algorithms that run MORE episodes, even if each episode is poor
- PETS runs ~100 episodes (low reward each) vs PSRL ~15 episodes (high reward each)
- Cumulative metric favors "doing many things poorly" over "learning to do things well"

**Results at 3000 Timesteps:**

**CartPole:**
- PSRL (with oracle): **2543.6 ± 48.1** (15 episodes × ~170 avg = 2550)
- PSRL (without oracle): **1353.6 ± 110.1**
- PETS: **2873.6 ± 21.1** (100 episodes × ~29 avg = 2900) ← Appears higher!

**Pendulum:**
- PSRL (with oracle): **-8936.8 ± 553.2** (15 episodes × -596 avg)
- PSRL (without oracle): **-11627.2 ± 636.7**
- PETS: **-26126.4 ± 133.1** (15 episodes × -1742 avg) ← Clearly worse

**Why PETS appears competitive in CartPole cumulative plot:**

Example breakdown:
- **PETS**: Runs 100 episodes, each getting ~20-60 reward
  - Episode 0-10: 20-60 reward each = ~400 total
  - Episode 11-50: 20-60 reward each = ~1500 total  
  - Episode 51-100: 20-60 reward each = ~1500 total
  - **Total: ~3000 cumulative** over 2800-3000 timesteps
  
- **PSRL WITH oracle**: Runs 15 episodes, quickly achieving ~200 reward each
  - Episode 0-3: 20-150 reward (learning phase) = ~400 total
  - Episode 4-14: ~200 reward each (optimal) = ~2200 total
  - **Total: ~2600 cumulative** over 2000-3000 timesteps

**The paradox:** PETS accumulates rewards faster because it "fails fast" - many short episodes. PSRL accumulates slower because episodes last longer (200 steps vs 20-60 steps). But PSRL achieves much better performance!

---

## Which Plot to Use?

### For Understanding Learning Performance: ✓ Episode-Based
- Shows how well the agent learns the task
- Directly comparable across algorithms
- Matches how we evaluate RL algorithms in literature
- Clear winner: PSRL > PETS

### For Understanding Sample Efficiency: ⚠️ Timestep-Based (with caution)
- Shows cumulative reward over interaction timesteps
- Can be useful for sample efficiency comparisons
- BUT: Misleading when algorithms have different episode lengths
- In our case: Makes PETS look competitive when it's actually failing

---

## Recommendation

**Use the Episode-Based Learning Curves** (`*_learning_curves.png`) as your primary comparison plots. These clearly show:

1. **PSRL with oracle** achieves near-optimal performance quickly
2. **PSRL without oracle** learns well but with more variance
3. **PETS** fails to learn effectively, staying at low performance

The episode-based view correctly represents the goal of reinforcement learning: learning to maximize reward per episode, not just accumulating rewards by doing many poor episodes.

---

## Technical Note

Both algorithms target ~3000 timesteps total, but achieve this differently:
- **PSRL**: 15 episodes × ~200 steps/episode = ~3000 timesteps (high performance)
- **PETS**: 100 episodes × ~30 steps/episode = ~3000 timesteps (low performance)

The episode-based plot normalizes for this difference and shows true learning quality.
