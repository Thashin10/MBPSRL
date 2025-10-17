"""
Comparison plots for PSRL vs PETS
Generates smooth plots with mean and standard error bands
"""

import numpy as np
import matplotlib.pyplot as plt
from scipy.ndimage import gaussian_filter1d

def load_timestep_data(filename):
    """Load timestep reward data - file contains [timestep, cumulative_reward] pairs"""
    data = np.loadtxt(filename)
    # Extract just the cumulative rewards (second column)
    cumulative_rewards = data[:, 1]
    return cumulative_rewards

def smooth_data(data, window=400, passes=2):
    """Apply Gaussian smoothing"""
    smoothed = data.copy()
    for _ in range(passes):
        smoothed = gaussian_filter1d(smoothed, sigma=window/6, mode='nearest')
    return smoothed

def compute_mean_and_se(data_list, cutoff=2800):
    """
    Compute mean and standard error across seeds
    
    Args:
        data_list: List of arrays (one per seed)
        cutoff: Cutoff timestep
    
    Returns:
        mean, standard_error, timesteps
    """
    # Truncate all to same length
    min_len = min(len(d) for d in data_list)
    min_len = min(min_len, cutoff)
    
    data_array = np.array([d[:min_len] for d in data_list])
    
    mean = np.mean(data_array, axis=0)
    std = np.std(data_array, axis=0)
    se = std / np.sqrt(len(data_list))
    
    timesteps = np.arange(min_len)
    
    return mean, se, timesteps

def plot_comparison(env_name, cutoff=2800, window=400, passes=2):
    """
    Create comparison plot for one environment
    
    Args:
        env_name: 'cartpole' or 'pendulum'
        cutoff: Cutoff timestep
        window: Smoothing window size
        passes: Number of smoothing passes
    """
    print("\nProcessing {}...".format(env_name))
    
    # Load PSRL data
    psrl_with = []
    psrl_without = []
    for seed in range(5):
        # PSRL WITH oracle
        data = load_timestep_data('seeds_data/{}_timestep_rewards_with_oracle_seed{}.txt'.format(env_name, seed))
        psrl_with.append(data)
        
        # PSRL WITHOUT oracle
        data = load_timestep_data('seeds_data/{}_timestep_rewards_without_oracle_seed{}.txt'.format(env_name, seed))
        psrl_without.append(data)
    
    # Load PETS data
    pets = []
    for seed in range(5):
        data = load_timestep_data('seeds_data/pets_{}_timestep_rewards_seed{}.txt'.format(env_name, seed))
        pets.append(data)
    
    # Smooth all data
    print("  Smoothing data (window={}, passes={})...".format(window, passes))
    psrl_with_smooth = [smooth_data(d, window, passes) for d in psrl_with]
    psrl_without_smooth = [smooth_data(d, window, passes) for d in psrl_without]
    pets_smooth = [smooth_data(d, window, passes) for d in pets]
    
    # Compute mean and SE
    print("  Computing statistics...")
    psrl_with_mean, psrl_with_se, timesteps_with = compute_mean_and_se(psrl_with_smooth, cutoff)
    psrl_without_mean, psrl_without_se, timesteps_without = compute_mean_and_se(psrl_without_smooth, cutoff)
    pets_mean, pets_se, timesteps_pets = compute_mean_and_se(pets_smooth, cutoff)
    
    # Create plot
    print("  Creating plot...")
    fig, ax = plt.subplots(figsize=(10, 6))
    
    # Plot PSRL WITH oracle
    ax.plot(timesteps_with, psrl_with_mean, 'b-', linewidth=2, label='PSRL (with oracle)', alpha=0.9)
    ax.fill_between(timesteps_with, 
                     (psrl_with_mean - psrl_with_se).flatten(), 
                     (psrl_with_mean + psrl_with_se).flatten(),
                     color='b', alpha=0.2)
    
    # Plot PSRL WITHOUT oracle
    ax.plot(timesteps_without, psrl_without_mean, 'g-', linewidth=2, label='PSRL (without oracle)', alpha=0.9)
    ax.fill_between(timesteps_without,
                     (psrl_without_mean - psrl_without_se).flatten(),
                     (psrl_without_mean + psrl_without_se).flatten(),
                     color='g', alpha=0.2)
    
    # Plot PETS
    ax.plot(timesteps_pets, pets_mean, 'r-', linewidth=2, label='PETS', alpha=0.9)
    ax.fill_between(timesteps_pets,
                     (pets_mean - pets_se).flatten(),
                     (pets_mean + pets_se).flatten(),
                     color='r', alpha=0.2)
    
    # Formatting
    ax.set_xlabel('Timesteps', fontsize=12)
    ax.set_ylabel('Cumulative Reward', fontsize=12)
    ax.set_title('{} - Algorithm Comparison (5 seeds)'.format(env_name.capitalize()), fontsize=14, fontweight='bold')
    ax.legend(loc='best', fontsize=11, framealpha=0.9)
    ax.grid(True, alpha=0.3)
    
    # Save plots
    plt.tight_layout()
    plt.savefig('comparison_{}.png'.format(env_name), dpi=300, bbox_inches='tight')
    plt.savefig('comparison_{}.svg'.format(env_name), bbox_inches='tight')
    print("  Saved: comparison_{}.png and .svg".format(env_name))
    
    # Print summary statistics
    print("\n  Final rewards at timestep {}:".format(cutoff))
    print("    PSRL (with oracle):    {:.1f} ± {:.1f}".format(psrl_with_mean[-1], psrl_with_se[-1]))
    print("    PSRL (without oracle): {:.1f} ± {:.1f}".format(psrl_without_mean[-1], psrl_without_se[-1]))
    print("    PETS:                  {:.1f} ± {:.1f}".format(pets_mean[-1], pets_se[-1]))
    
    plt.close()

if __name__ == '__main__':
    print("="*60)
    print("PSRL vs PETS Comparison Plots")
    print("="*60)
    
    # CartPole
    plot_comparison('cartpole', cutoff=2800, window=400, passes=2)
    
    # Pendulum  
    plot_comparison('pendulum', cutoff=2800, window=400, passes=2)
    
    print("\n" + "="*60)
    print("All comparison plots generated successfully!")
    print("="*60)
