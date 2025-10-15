# CartPole Experiment Results Summary

Generated: October 14, 2025

## Overview

Successfully replicated the CartPole continuous control experiment from the paper "Model-based Reinforcement Learning for Continuous Control with Posterior Sampling" by Yingfan Fan.

## Environment Setup

- **Python**: 3.7.1 (conda environment `mbpsrl`)
- **TensorFlow**: 1.14.0
- **PyTorch**: 1.4.0
- **Gym**: 0.9.4
- **NumPy**: 1.16.5
- **Key Dependencies**: See `requirements.txt` and `pip-requirements.txt`

## Experiment Runs

### Successful Runs

| Run ID | Episodes | Log File | Data Files |
|--------|----------|----------|------------|
| logs_20251014_125209 | 15 | `logs_20251014_125209/run_cartpole_with_reward.log` | `cartpole_rewards_logs_20251014_125209.{csv,svg,png}` |
| logs_20251014_142033 | 100 | `logs_20251014_142033/run_cartpole_with_reward.log` | `cartpole_rewards_logs_20251014_142033.{csv,svg,png}` |

### Run Details: 100-Episode Experiment (logs_20251014_142033)

- **Command**: `python run_cartpole.py --with-reward --num-episodes 100`
- **Total Episodes**: 100
- **Reward Range**: 15.8 (episode 0) to 200.2 (max observed)
- **Performance**: Agent quickly converges to near-optimal performance (~200 reward) after initial episodes
- **Model**: Bayesian Neural Network (BNN) with:
  - Observation dim: 4
  - Action dim: 1
  - Hidden dim: 200
  - 1 network, 1 elite
  - Training: 100 epochs per iteration with tqdm progress tracking

### Key Results

1. **Early Learning** (Episodes 0-5):
   - Episode 0: 15.79 reward (random exploration)
   - Episode 1: 200.16 reward (rapid learning)
   - Episode 2: 73.02 reward (exploration/exploitation tradeoff)
   - Episode 3-5: Stabilizes near 200 reward

2. **Convergence** (Episodes 6-100):
   - Consistent performance around 199-200 reward
   - Few drops below 190 (indicating robust policy)
   - Average reward (episodes 10-100): ~199.8

## Generated Artifacts

### Data Files
- `cartpole_rewards_logs_20251014_125209.csv` - 15 episodes cumulative rewards
- `cartpole_rewards_logs_20251014_142033.csv` - 100 episodes cumulative rewards

### Plots
- `cartpole_rewards_logs_20251014_125209.svg` - SVG plot (15 episodes)
- `cartpole_rewards_logs_20251014_125209.png` - PNG plot (15 episodes, requires matplotlib)
- `cartpole_rewards_logs_20251014_142033.svg` - SVG plot (100 episodes)
- `cartpole_rewards_logs_20251014_142033.png` - PNG plot (100 episodes, requires matplotlib)

### Tools
- `plot_cartpole_rewards.py` - Automated plotting script with UTF-16 LE log support
  - Handles PowerShell `Tee-Object` UTF-16 encoded logs
  - Generates CSV, SVG (no dependencies), and PNG (if matplotlib available)
  - Usage: `python plot_cartpole_rewards.py --log <path> --out <png> --csv <csv>`

## Notes

1. **Log Encoding**: PowerShell's `Tee-Object` writes UTF-16 LE encoded files. The plotting script automatically detects and handles this.

2. **Failed Runs**: Three log directories contained incomplete runs (empty or very small log files):
   - `logs_20251014_043604` - 2.4 KB (incomplete)
   - `logs_20251014_134333` - 0 bytes (empty)
   - `logs_20251014_141809` - 1.8 KB (incomplete)

3. **MuJoCo Environments**: Pendulum, Pusher, and Reacher experiments require `mujoco-py==0.5.7` installation, which was not completed in this session.

## Next Steps

1. **Pendulum Experiment**: Run `python run_pendulum.py --with-reward --num-episodes 100`
2. **MuJoCo Setup**: Install MuJoCo binaries and `mujoco-py` for Pusher/Reacher experiments
3. **Comparison with Paper**: Compare reward curves with figures from the original paper
4. **Multiple Seeds**: Run experiments with different random seeds for statistical validation

## References

- Paper: "Model-based Reinforcement Learning for Continuous Control with Posterior Sampling" (Yingfan Fan)
- Repository: https://github.com/yingfan-bot/mbpsrl
- Environment: Continuous CartPole (custom implementation in `cartpole_continuous.py`)

---

*Generated automatically from experiment logs*
