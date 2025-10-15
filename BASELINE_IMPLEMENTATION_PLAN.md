"""
BASELINE IMPLEMENTATIONS PLAN
==============================

This document outlines the implementation plan for MBPO and PETS baselines
as shown in the paper's Figure 1.

## Paper Reference
Model-based Reinforcement Learning for Continuous Control with Posterior Sampling
https://arxiv.org/abs/2012.09613

## Baselines in Figure 1:
1. **MPC-PSRL** (Red line) - Our current implementation ✓
2. **MBPO** (Green line) - Model-Based Policy Optimization
3. **PETS** (Yellow line) - Probabilistic Ensembles with Trajectory Sampling

---

## 1. MBPO (Model-Based Policy Optimization)
**Reference Paper:** Janner et al. (2019) "When to Trust Your Model: Model-Based Policy Optimization"

### Key Components:
- Uses an ensemble of learned dynamics models
- Trains a model-free RL agent (SAC - Soft Actor-Critic) on a mixture of:
  - Real environment data
  - Synthetic rollouts from the learned model
- Branched rollouts from real states to generate synthetic data
- Short horizon rollouts to reduce model bias

### Implementation Requirements:
1. **Dynamics Model Ensemble:**
   - Use existing BNN ensemble from tf_models/bnn.py
   - Train ensemble on collected transitions
   - Ensemble size: typically 7 networks, use top 5 elites

2. **SAC Policy:**
   - Actor network (policy): μ(s) and σ(s) 
   - Two critic networks Q1(s,a) and Q2(s,a)
   - Entropy temperature α
   - Target networks for critics

3. **Algorithm Flow:**
   ```
   for each episode:
       1. Collect D_env transitions from real environment
       2. Train dynamics model ensemble on D_env
       3. For k branch steps:
           a. Sample state s from D_env
           b. Roll out k steps using learned model and policy
           c. Add synthetic transitions to D_model
       4. Train SAC on D_env ∪ D_model
       5. Execute policy in environment
   ```

4. **Hyperparameters (from typical MBPO papers):**
   - Model rollout length: 1-5 steps (increases over training)
   - Model ensemble: 7 networks, 5 elites
   - SAC: α=0.2, τ=0.005, γ=0.99
   - Replay buffer: 1e6
   - Training steps: Match paper's 3000 timesteps for fair comparison

### Files to Create:
- `sac_agent.py` - SAC implementation
- `mbpo_trainer.py` - Main MBPO training loop
- `run_mbpo_cartpole.py` - CartPole with MBPO
- `run_mbpo_pendulum.py` - Pendulum with MBPO

---

## 2. PETS (Probabilistic Ensembles with Trajectory Sampling)
**Reference Paper:** Chua et al. (2018) "Deep Reinforcement Learning in a Handful of Trials using Probabilistic Dynamics Models"

### Key Components:
- Probabilistic ensemble of neural networks (similar to current BNN)
- Model Predictive Control (MPC) using Cross-Entropy Method (CEM)
- Trajectory sampling (TS) for action selection
- No policy learning - pure model-based planning

### Implementation Requirements:
1. **Dynamics Model Ensemble:**
   - Use existing BNN ensemble (already have this!)
   - Output: mean and variance of next state
   - Ensemble size: typically 5 networks

2. **CEM Planning:**
   - Already implemented in CEM_with.py and CEM_without.py!
   - Sample action sequences
   - Evaluate using learned model
   - Select elite sequences
   - Refit distribution and repeat

3. **Trajectory Sampling (TS):**
   - For each candidate action sequence:
     a. Randomly select one model from ensemble
     b. Use that model consistently for the entire trajectory
     c. Evaluate trajectory cost
   - This differs from mean prediction across ensemble

4. **Algorithm Flow:**
   ```
   for each episode:
       for each timestep:
           1. Use CEM with TS to find optimal action sequence
           2. Execute first action
           3. Observe transition (s, a, r, s')
           4. Add to dataset D
           5. Retrain ensemble on D every N steps
   ```

5. **Hyperparameters:**
   - Ensemble: 5 networks
   - CEM particles: 500
   - CEM elites: 50  
   - Planning horizon: 30 steps
   - CEM iterations: 5

### Files to Create:
- `run_pets_cartpole.py` - CartPole with PETS
- `run_pets_pendulum.py` - Pendulum with PETS
- May need to modify CEM_with.py to use trajectory sampling

---

## Key Differences Between Current Implementation and Baselines:

### MPC-PSRL (Current):
- Bayesian Linear Regression for uncertainty
- Thompson Sampling from posterior
- CEM for planning
- Single network (not ensemble)

### PETS:
- Ensemble of networks for uncertainty
- Trajectory sampling (random model per rollout)
- CEM for planning
- No learned reward model

### MBPO:
- Ensemble of networks
- Learns a policy (SAC)
- Uses model for synthetic data generation
- Model-free + Model-based hybrid

---

## Implementation Priority:

### PETS (Easier - Most similar to current code):
**Similarity:** ~80%
- Already have: BNN ensemble, CEM planning, environment interface
- Need to add: Trajectory sampling in CEM, ensemble model selection
- Estimated effort: 2-3 hours
- High confidence in correctness

### MBPO (Harder - Requires SAC):
**Similarity:** ~40%  
- Already have: BNN ensemble, environment interface
- Need to implement: Complete SAC agent, replay buffers, synthetic rollouts
- Estimated effort: 6-8 hours
- Medium confidence (SAC is complex)

---

## Recommendation:

**Start with PETS** because:
1. Minimal modifications to existing code
2. Same evaluation protocol (CEM planning)
3. Can reuse most infrastructure
4. Higher confidence in matching paper's implementation

**Then implement MBPO** if time permits:
1. Requires substantial new code (SAC agent)
2. Different evaluation protocol
3. May need hyperparameter tuning to match paper
4. Reference implementations available (e.g., spinning up, stable-baselines3)

---

## Data Requirements for Fair Comparison:

All methods should use:
- Same environments (CartPole, Pendulum)
- Same total timesteps (3000)
- Same random seeds (for statistical validity)
- Same evaluation protocol
- Same data collection (episodes of 200 steps, 15 episodes total)

---

## Next Steps:

1. ✓ Complete multi-seed PSRL runs (in progress)
2. Implement PETS (modify CEM for trajectory sampling)
3. Run PETS with same seeds
4. Implement MBPO (if time allows)
5. Generate combined plots with all baselines

---

## Notes on Paper Implementation:

The paper likely used existing baseline implementations:
- MBPO: Original implementation from https://github.com/JannerM/mbpo
- PETS: Original implementation from https://github.com/kchua/handful-of-trials

For exact replication, we may want to:
- Check if paper provides hyperparameters
- Use same network architectures
- Match training schedules exactly
- Verify evaluation metrics match

---

## Files Structure:

```
mbpsrl/
├── baselines/
│   ├── __init__.py
│   ├── pets/
│   │   ├── __init__.py
│   │   ├── run_pets_cartpole.py
│   │   └── run_pets_pendulum.py
│   └── mbpo/
│       ├── __init__.py
│       ├── sac_agent.py
│       ├── mbpo_trainer.py
│       ├── run_mbpo_cartpole.py
│       └── run_mbpo_pendulum.py
├── plot_all_baselines.py  # Combined plotting
└── run_all_baselines.ps1  # Orchestration script
```
"""