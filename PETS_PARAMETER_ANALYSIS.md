# PETS Parameter Analysis and Recommendation

## Current Situation

We ran PETS experiments with **REDUCED parameters** to save computational time:

### Parameters Used (Reduced):
| Parameter | Paper Value | Our Value | Reduction Factor |
|-----------|-------------|-----------|------------------|
| **CartPole** | | | |
| Trajectories (K) | 500 | 100 | 5x fewer |
| Planning horizon (H_p) | 30 | 15 | 2x shorter |
| CEM iterations (I) | 5 | 3 | 1.7x fewer |
| Elites (E) | 50 | 50 | ✓ Same |
| Episodes | 15 | 100 | Different strategy* |
| **Pendulum** | | | |
| Trajectories (K) | 100 | 100 | ✓ Same |
| Planning horizon (H_p) | 30 | 15 | 2x shorter |
| CEM iterations (I) | 5 | 3 | 1.7x fewer |
| Elites (E) | 5 | Default | Need to verify |

*We ran 100 episodes to reach 3000 timesteps total, while paper intended 15 episodes × 200 steps = 3000 timesteps

## Performance Impact

### Observed Results (Reduced Parameters):
**CartPole:**
- Mean reward: ~28-29 per episode
- Maximum: 113 (rare outlier at episode 82)
- Typical range: 20-40
- PSRL Episode 14: 196.87 ± 6.06 (6.8x better!)

**Pendulum:**
- Mean reward: -1767.80 ± 66.31
- PSRL Episode 14: -358.10 ± 4.03 (4.9x better!)

### Why Reduced Parameters Hurt Performance:

1. **5x fewer trajectories (100 vs 500)**
   - Less exploration of action space
   - Higher chance of missing good action sequences
   - CEM converges to suboptimal local maxima

2. **2x shorter planning horizon (15 vs 30)**
   - Can only plan 15 steps ahead instead of 30
   - Myopic decisions that don't consider long-term consequences
   - In CartPole: Can't anticipate pole falling over as early

3. **1.7x fewer CEM iterations (3 vs 5)**
   - Less refinement of action distribution
   - Coarser optimization of action sequences
   - May not converge to good solutions

### Computational Cost:

**Reduced parameters (100/15/3):**
- ~1-2 minutes per episode
- ~100-200 minutes per seed for 100 episodes
- Total: ~8-16 hours for 5 seeds × 2 environments

**Full paper parameters (500/30/5):**
- ~15-20 minutes per episode (10-15x slower!)
- ~225-300 minutes per seed for 15 episodes
- Total: ~20-25 hours for 5 seeds × 1 environment

## Recommendation

### Option 1: Re-run with Full Paper Parameters (BEST for accuracy)

**Pros:**
- Results will match paper's PETS performance
- Fair comparison with PSRL
- More scientifically valid
- PETS should perform significantly better (estimate: 100-150 reward range for CartPole)

**Cons:**
- Takes ~20-25 hours per environment
- Total: ~40-50 hours for both environments

**Action Plan:**
1. Keep existing "lightweight PETS" results for reference
2. Run new experiments with full parameters, save to `pets_full_*` files
3. Compare lightweight vs full PETS in plots
4. Use full PETS for final paper comparisons

### Option 2: Document and Keep Reduced Parameters

**Pros:**
- No additional computation needed
- Still shows PSRL > PETS (the main point)
- Can frame as "lightweight PETS for computational efficiency"

**Cons:**
- Not a fair comparison (handicapped PETS)
- Results don't match paper
- Reviewers may question validity
- Can't claim we replicated PETS properly

**Action Plan:**
1. Clearly label results as "PETS with reduced parameters (100/15/3)"
2. Add footnote explaining computational constraints
3. Note that full PETS would perform better
4. Focus comparison on PSRL WITH vs WITHOUT oracle

### Option 3: Hybrid Approach (RECOMMENDED)

**Pros:**
- Run just 1-2 seeds with full parameters as validation
- Show that full PETS performs better
- Keep reduced PETS for 5-seed statistics
- Best balance of accuracy and time

**Cons:**
- Mixed parameter sets in final results
- More complex to explain

**Action Plan:**
1. Run CartPole seeds 0-1 with full parameters (~8-10 hours)
2. Compare Seed 0 reduced vs full to quantify improvement
3. Extrapolate expected full performance: "Full PETS achieves ~X reward (estimated from seeds 0-1 with full parameters)"
4. Keep 5-seed reduced results for variability analysis

## Paper Specifications Summary

From the paper, PETS should use:

### CartPole:
```
--num-trajs 500          # K = 500 trajectories
--num-elites 50          # E = 50 elites  
--plan-hor 30            # H_p = 30 steps
--max-iters 5            # I = 5 CEM iterations
--alpha 0.1              # α = 0.1 smoothing
--var 1.0                # Initial variance
--num-episodes 15        # 15 episodes × 200 steps = 3000 timesteps
```

### Pendulum:
```
--num-trajs 100          # K = 100 trajectories
--num-elites 5           # E = 5 elites
--plan-hor 30            # H_p = 30 steps
--max-iters 5            # I = 5 CEM iterations
--alpha 0.0              # α = 0.0 (no smoothing)
--var 3.0                # Initial variance
--num-episodes 15        # 15 episodes × 200 steps = 3000 timesteps
```

## Time Estimates

### Single Episode Time:
- Reduced (100/15/3): ~1-2 minutes
- Full (500/30/5): ~15-20 minutes

### Per Seed (15 episodes):
- Reduced: ~15-30 minutes
- Full: ~225-300 minutes (~4-5 hours)

### Full Experiment (5 seeds):
- Reduced: ~1.5-2.5 hours
- Full: ~20-25 hours

## Decision Required

Please choose one of the following:

1. **Re-run everything with full parameters** (~40-50 hours total)
   - Most accurate comparison
   - Best for publication

2. **Keep reduced parameters, document clearly**
   - No additional time
   - Still shows PSRL superiority
   - Less scientifically rigorous

3. **Hybrid: Run 1-2 seeds with full params** (~8-10 hours)
   - Validate that full PETS performs better
   - Keep reduced for statistics
   - Good balance

**My recommendation: Option 3 (Hybrid)** - Run seeds 0-1 with full parameters for CartPole to validate improvement, extrapolate for the rest, and focus the paper on PSRL WITH vs WITHOUT oracle comparison where both use the same parameters.
