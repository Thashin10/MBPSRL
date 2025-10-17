"""
Paper-style learning curves: Per-episode rewards with mean and standard error
Shows learning progression comparing PSRL vs PETS
"""

import numpy as np
import matplotlib.pyplot as plt
from scipy.ndimage import gaussian_filter1d

def load_episode_rewards(filename):
    """Load episode rewards from log file"""
    data = np.loadtxt(filename)
    episodes = data[:, 0].astype(int)
    rewards = data[:, 1]
    return episodes, rewards

def smooth_data(data, window=10, passes=2):
    """Apply Gaussian smoothing"""
    smoothed = data.copy()
    for _ in range(passes):
        smoothed = gaussian_filter1d(smoothed, sigma=window/6, mode='nearest')
    return smoothed

def compute_mean_and_se(data_list, max_episodes=None):
    """Compute mean and standard error across seeds"""
    if max_episodes is None:
        max_episodes = min(len(d) for d in data_list)
    
    # Truncate all to same length
    data_array = np.array([d[:max_episodes] for d in data_list])
    
    mean = np.mean(data_array, axis=0)
    std = np.std(data_array, axis=0)
    se = std / np.sqrt(len(data_list))
    
    episodes = np.arange(max_episodes)
    
    return mean, se, episodes

def plot_learning_curves(env_name, max_episodes=15, smooth_window=3):
    """Create paper-style learning curve plot"""
    print("\nProcessing {}...".format(env_name))
    
    # Load PSRL data
    psrl_with_rewards = []
    psrl_without_rewards = []
    for seed in range(5):
        _, rewards = load_episode_rewards('seeds_data/{}_log_with_oracle_seed{}.txt'.format(env_name, seed))
        psrl_with_rewards.append(rewards)
        
        _, rewards = load_episode_rewards('seeds_data/{}_log_without_oracle_seed{}.txt'.format(env_name, seed))
        psrl_without_rewards.append(rewards)
    
    # Load PETS data
    pets_rewards = []
    for seed in range(5):
        _, rewards = load_episode_rewards('seeds_data/pets_{}_log_seed{}.txt'.format(env_name, seed))
        pets_rewards.append(rewards)
    
    # Determine max episodes
    max_ep_psrl = min(len(r) for r in psrl_with_rewards)
    max_ep_pets = min(len(r) for r in pets_rewards)
    
    print("  PSRL episodes: {}, PETS episodes: {}".format(max_ep_psrl, max_ep_pets))
    print("  Plotting first {} episodes".format(max_episodes))
    
    # Smooth data
    psrl_with_smooth = [smooth_data(r, window=smooth_window, passes=2) for r in psrl_with_rewards]
    psrl_without_smooth = [smooth_data(r, window=smooth_window, passes=2) for r in psrl_without_rewards]
    pets_smooth = [smooth_data(r, window=smooth_window, passes=2) for r in pets_rewards]
    
    # Compute mean and SE
    psrl_with_mean, psrl_with_se, episodes = compute_mean_and_se(psrl_with_smooth, max_episodes)
    psrl_without_mean, psrl_without_se, _ = compute_mean_and_se(psrl_without_smooth, max_episodes)
    pets_mean, pets_se, _ = compute_mean_and_se(pets_smooth, max_episodes)
    
    # Create plot
    fig, ax = plt.subplots(figsize=(10, 6))
    
    # Plot PSRL WITH oracle
    ax.plot(episodes, psrl_with_mean, 'b-', linewidth=2.5, label='PSRL (with oracle)', alpha=0.9)
    ax.fill_between(episodes, 
                     psrl_with_mean - psrl_with_se, 
                     psrl_with_mean + psrl_with_se,
                     color='b', alpha=0.2)
    
    # Plot PSRL WITHOUT oracle
    ax.plot(episodes, psrl_without_mean, 'g-', linewidth=2.5, label='PSRL (without oracle)', alpha=0.9)
    ax.fill_between(episodes,
                     psrl_without_mean - psrl_without_se,
                     psrl_without_mean + psrl_without_se,
                     color='g', alpha=0.2)
    
    # Plot PETS
    ax.plot(episodes, pets_mean, 'r-', linewidth=2.5, label='PETS', alpha=0.9)
    ax.fill_between(episodes,
                     pets_mean - pets_se,
                     pets_mean + pets_se,
                     color='r', alpha=0.2)
    
    # Formatting
    ax.set_xlabel('Episode', fontsize=14, fontweight='bold')
    ax.set_ylabel('Average Reward', fontsize=14, fontweight='bold')
    ax.set_title('{} - Learning Curves'.format(env_name.capitalize()), 
                 fontsize=16, fontweight='bold')
    ax.legend(loc='best', fontsize=12, framealpha=0.95, edgecolor='black')
    ax.grid(True, alpha=0.3, linestyle='--')
    ax.tick_params(labelsize=11)
    
    # Save plots
    plt.tight_layout()
    plt.savefig('{}_learning_curves.png'.format(env_name), dpi=300, bbox_inches='tight')
    plt.savefig('{}_learning_curves.svg'.format(env_name), bbox_inches='tight')
    print("  Saved: {}_learning_curves.png and .svg".format(env_name))
    
    # Print summary
    print("\n  Episode {} rewards:".format(max_episodes-1))
    print("    PSRL (with oracle):    {:.1f} +/- {:.1f}".format(psrl_with_mean[-1], psrl_with_se[-1]))
    print("    PSRL (without oracle): {:.1f} +/- {:.1f}".format(psrl_without_mean[-1], psrl_without_se[-1]))
    print("    PETS:                  {:.1f} +/- {:.1f}".format(pets_mean[-1], pets_se[-1]))
    
    plt.close()

if __name__ == '__main__':
    print("="*70)
    print(" "*15 + "Paper-Style Learning Curves")
    print("="*70)
    
    # CartPole - first 15 episodes
    plot_learning_curves('cartpole', max_episodes=15, smooth_window=3)
    
    # Pendulum - 15 episodes
    plot_learning_curves('pendulum', max_episodes=15, smooth_window=3)
    
    print("\n" + "="*70)
    print(" "*20 + "Plots Generated Successfully!")
    print("="*70)
