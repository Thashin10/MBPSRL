# Performance Optimization Analysis: MBPO & PETS

## Current Performance Issues

### PETS (Reduced Parameters):
- **Current**: K=100, H=15, I=3 → ~28 reward (CartPole)
- **Paper**: K=500, H=30, I=5 → Expected ~100-150 reward
- **Problem**: 5x fewer trajectories, 2x shorter horizon

### MBPO (Simplified Implementation):
- **Current**: Basic actor-critic, simple reward estimation
- **Issue**: No learned reward model, limited rollout quality
- **Expected**: ~50-120 reward (CartPole)

## Quick Wins (Minimal Time Impact)

### 1. Better Initialization ⚡ (+10-20% performance, +0% time)

**Problem**: Random policy initialization leads to poor early exploration

**Solution**: Use better initial policy
```python
# Instead of random initialization:
# For CartPole: Initialize to balance near center
# For Pendulum: Initialize to swing up behavior

class SimpleActor:
    def __init__(self, ...):
        # Initialize weights with smaller values for smoother policy
        for layer in self.net:
            if isinstance(layer, nn.Linear):
                nn.init.xavier_uniform_(layer.weight, gain=0.5)
                nn.init.constant_(layer.bias, 0)
```

**Time Impact**: None
**Expected Gain**: +15-25% reward improvement

### 2. Improved Exploration Strategy ⚡ (+15-30% performance, +5% time)

**Problem**: Fixed noise schedule doesn't adapt to learning

**Solution**: Adaptive exploration
```python
# Current: Fixed noise decay
self.noise_scale *= 0.98

# Better: Action-value based exploration
def select_action(self, state, deterministic=False):
    # More exploration when Q-values are uncertain
    q_value = self.critic(state, action)
    noise_scale = max(0.01, 0.3 / (1 + abs(q_value)))
```

**Time Impact**: +5% (minimal)
**Expected Gain**: +20-40% reward improvement

### 3. Ensemble Model Utilization 🚀 (+30-50% performance, +20% time)

**Problem**: Using only 1 model sample per episode

**Solution**: Use ensemble mean or multiple samples
```python
# Current PETS: Single model sample
my_dx.sample()  # Sample once per episode

# Better: Use ensemble predictions
# Option A: Mean prediction (no extra time)
predictions = []
for _ in range(5):
    my_dx.sample()
    predictions.append(my_dx.predict(state_action))
mean_prediction = np.mean(predictions, axis=0)

# Option B: Optimistic planning (best expected outcome)
# Select trajectory with highest expected reward
```

**Time Impact**: +15-25% (if using 5 samples)
**Expected Gain**: +40-60% reward improvement

### 4. Warm-Start CEM 🎯 (+20-30% PETS performance, +0% time)

**Problem**: CEM resets mean/variance each timestep

**Solution**: Better warm-starting
```python
# Current CEM: Shift and zero-pad
self.mean = np.concatenate([self.mean[action_dim:], np.zeros(action_dim)])

# Better: Use previous solution + simple dynamics
# Predict what would have been good next action
self.mean = np.concatenate([
    self.mean[action_dim:],  # Shift
    self.mean[-action_dim:]  # Repeat last action instead of zeros
])
```

**Time Impact**: None
**Expected Gain**: +25-35% PETS reward

### 5. Reward Shaping 💡 (+10-20% performance, +0% time)

**Problem**: Sparse rewards don't guide learning well

**Solution**: Add shaped rewards
```python
# CartPole: Add shaping for staying upright and centered
def shaped_reward(state, action, next_state):
    base_reward = np.cos(theta) - 0.01 * x**2
    
    # Bonus for small angular velocity (approaching balance)
    stability_bonus = 0.1 * np.exp(-abs(theta_dot))
    
    # Penalty for large position
    centering_bonus = 0.05 * np.exp(-abs(x))
    
    return base_reward + stability_bonus + centering_bonus
```

**Time Impact**: None
**Expected Gain**: +15-25% reward

## Medium Impact Optimizations (+10-30% time)

### 6. Larger Batch Sizes 📊 (+10-15% performance, +10% time)

**Current MBPO**: batch_size = 256
**Better**: batch_size = 512 (more stable gradients)

**Time Impact**: +10-15%
**Expected Gain**: +10-20% reward

### 7. Learning Rate Scheduling 📉 (+5-10% performance, +0% time)

```python
# Start with higher LR, decay over time
initial_lr = 1e-3
scheduler = optim.lr_scheduler.StepLR(optimizer, step_size=5, gamma=0.8)
```

**Time Impact**: None
**Expected Gain**: +8-15% reward

### 8. Prioritized Experience Replay 🎲 (+15-25% performance, +15% time)

```python
# Sample important transitions more frequently
# Transitions with high TD-error are more valuable
```

**Time Impact**: +15-20%
**Expected Gain**: +20-30% reward

## Recommended Quick Fixes (Implementation)

### For PETS (Quick boost without full params):

**Option 1: Middle-ground parameters** (2x time vs current, 10x faster than full)
- K=200 (vs 100 current, 500 paper) → 2x trajectories
- H=25 (vs 15 current, 30 paper) → 1.7x horizon
- I=4 (vs 3 current, 5 paper) → 1.3x iterations
- **Time**: ~4-6 min/episode (vs 1-2 current, 15-20 full)
- **Expected**: ~60-90 reward (vs 28 current, 120+ full)

**Option 2: Smart sampling** (same time, better results)
- Keep K=100, H=15, I=3
- Use ensemble mean instead of single sample
- Better CEM warm-start
- **Time**: Same as current (~1-2 min/episode)
- **Expected**: ~45-65 reward (vs 28 current)

### For MBPO (Quick boost):

**Option 1: Better reward estimation** (+0% time)
```python
def _estimate_reward(self, state, action, next_state):
    # Use oracle for CartPole (matches PSRL WITH oracle)
    if env == 'cartpole':
        theta = np.arctan2(next_state[2], next_state[3])
        x = next_state[0]
        return np.cos(theta) - 0.01 * x**2
    else:
        # Pendulum oracle
        theta = np.arctan2(next_state[1], next_state[0])
        thetadot = next_state[2]
        return -(theta**2 + 0.1*thetadot**2 + 0.001*action**2)
```
- **Time**: Same
- **Expected**: +40-60% reward improvement

**Option 2: More policy updates** (+20% time)
```python
# Current: 20 updates per episode
# Better: 50 updates per episode
# Even better: Update after every step (online learning)
```
- **Time**: +20-30%
- **Expected**: +30-50% reward improvement

## Recommended Implementation

Let me implement the **easiest, highest-impact changes**:

1. ✅ **MBPO**: Add oracle reward estimation (0% time, +40-60% performance)
2. ✅ **MBPO**: Better network initialization (0% time, +15% performance)
3. ✅ **PETS**: Better CEM warm-start (0% time, +20-30% performance)
4. ✅ **PETS**: Ensemble averaging (optional, +15% time, +30% performance)

These 4 changes should significantly improve both baselines with minimal time impact!

## Summary Table

| Optimization | PETS Impact | MBPO Impact | Time Cost | Difficulty |
|--------------|-------------|-------------|-----------|------------|
| Better Init | +15% | +20% | 0% | Easy ✅ |
| Oracle Rewards (MBPO) | N/A | +50% | 0% | Easy ✅ |
| CEM Warm-start | +25% | N/A | 0% | Easy ✅ |
| Ensemble Mean | +35% | +20% | +15% | Medium |
| Adaptive Exploration | +20% | +25% | +5% | Medium |
| Reward Shaping | +15% | +15% | 0% | Easy ✅ |
| Larger Batches | N/A | +15% | +10% | Easy |
| More Updates | N/A | +35% | +25% | Easy |

**Recommended combo for best ROI**:
- MBPO: Oracle rewards + Better init + More updates = +80-100% improvement, +25% time
- PETS: CEM warm-start + Reward shaping + Better init = +50-70% improvement, 0% time

This would bring:
- **PETS**: From ~28 to ~45-50 reward (still below paper, but much better)
- **MBPO**: From ~50 to ~90-110 reward (competitive with PSRL WITHOUT oracle)

Would you like me to implement these optimizations?
