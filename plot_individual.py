"""
Individual plots for PETS to verify data
"""

import numpy as np
import matplotlib.pyplot as plt
from scipy.ndimage import gaussian_filter1d

def load_timestep_data(filename):
    """Load timestep reward data - file contains [timestep, cumulative_reward] pairs"""
    data = np.loadtxt(filename)
    # Extract cumulative rewards (second column)
    cumulative = data[:, 1]
    # Compute per-step rewards from cumulative
    rewards = np.diff(cumulative, prepend=0)
    return rewards, cumulative

def smooth_data(data, window=400, passes=2):
    """Apply Gaussian smoothing"""
    smoothed = data.copy()
    for _ in range(passes):
        smoothed = gaussian_filter1d(smoothed, sigma=window/6, mode='nearest')
    return smoothed

def plot_individual_seeds(env_name, algorithm, cutoff=2800):
    """Plot individual seeds for one algorithm"""
    fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(12, 10))
    
    colors = ['b', 'g', 'r', 'c', 'm']
    
    # Plot per-step rewards
    for seed in range(5):
        if algorithm == 'PETS':
            filename = 'seeds_data/pets_{}_timestep_rewards_seed{}.txt'.format(env_name, seed)
        elif algorithm == 'PSRL_WITH':
            filename = 'seeds_data/{}_timestep_rewards_with_oracle_seed{}.txt'.format(env_name, seed)
        else:
            filename = 'seeds_data/{}_timestep_rewards_without_oracle_seed{}.txt'.format(env_name, seed)
        
        rewards, cumulative = load_timestep_data(filename)
        
        # Truncate to cutoff
        rewards = rewards[:cutoff]
        cumulative = cumulative[:cutoff]
        timesteps = np.arange(len(rewards))
        
        # Smooth
        rewards_smooth = smooth_data(rewards, window=400, passes=2)
        cumulative_smooth = smooth_data(cumulative, window=400, passes=2)
        
        # Plot per-step rewards
        ax1.plot(timesteps, rewards_smooth, color=colors[seed], linewidth=1.5, 
                label='Seed {}'.format(seed), alpha=0.8)
        
        # Plot cumulative rewards
        ax2.plot(timesteps, cumulative_smooth, color=colors[seed], linewidth=1.5,
                label='Seed {}'.format(seed), alpha=0.8)
        
        print("Seed {}: {} timesteps, final cumulative reward = {:.1f}".format(
            seed, len(rewards), cumulative[-1]))
    
    # Format per-step rewards plot
    ax1.set_xlabel('Timesteps', fontsize=12)
    ax1.set_ylabel('Per-Step Reward', fontsize=12)
    ax1.set_title('{} {} - Per-Step Rewards (smoothed)'.format(
        env_name.capitalize(), algorithm), fontsize=14, fontweight='bold')
    ax1.legend(loc='best', fontsize=10)
    ax1.grid(True, alpha=0.3)
    
    # Format cumulative rewards plot
    ax2.set_xlabel('Timesteps', fontsize=12)
    ax2.set_ylabel('Cumulative Reward', fontsize=12)
    ax2.set_title('{} {} - Cumulative Rewards (smoothed)'.format(
        env_name.capitalize(), algorithm), fontsize=14, fontweight='bold')
    ax2.legend(loc='best', fontsize=10)
    ax2.grid(True, alpha=0.3)
    
    plt.tight_layout()
    plt.savefig('individual_{}_{}.png'.format(env_name, algorithm), dpi=300, bbox_inches='tight')
    print("Saved: individual_{}_{}.png\n".format(env_name, algorithm))
    plt.close()

if __name__ == '__main__':
    print("="*60)
    print("Individual Algorithm Plots")
    print("="*60)
    
    # CartPole
    print("\nCartPole PSRL WITH oracle:")
    plot_individual_seeds('cartpole', 'PSRL_WITH', cutoff=2800)
    
    print("CartPole PSRL WITHOUT oracle:")
    plot_individual_seeds('cartpole', 'PSRL_WITHOUT', cutoff=2800)
    
    print("CartPole PETS:")
    plot_individual_seeds('cartpole', 'PETS', cutoff=2800)
    
    # Pendulum
    print("Pendulum PSRL WITH oracle:")
    plot_individual_seeds('pendulum', 'PSRL_WITH', cutoff=2800)
    
    print("Pendulum PSRL WITHOUT oracle:")
    plot_individual_seeds('pendulum', 'PSRL_WITHOUT', cutoff=2800)
    
    print("Pendulum PETS:")
    plot_individual_seeds('pendulum', 'PETS', cutoff=2800)
    
    print("\n" + "="*60)
    print("All individual plots generated!")
    print("="*60)
