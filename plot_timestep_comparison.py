"""
Timestep-based learning curves: Cumulative rewards over 3000 timesteps
Comparing PSRL vs PETS with mean and standard error across 5 seeds
"""

import numpy as np
import matplotlib.pyplot as plt
from scipy.ndimage import gaussian_filter1d

def load_and_interpolate_timestep_data(filename, target_timesteps=3000):
    """Load timestep data and interpolate to common timestep grid"""
    data = np.loadtxt(filename)
    timesteps = data[:, 0].astype(int)
    cumulative_rewards = data[:, 1]
    
    # Interpolate to common timestep grid
    target_grid = np.arange(1, target_timesteps + 1)
    interpolated = np.interp(target_grid, timesteps, cumulative_rewards)
    
    return interpolated

def smooth_data(data, window=400, passes=2):
    """Apply Gaussian smoothing"""
    smoothed = data.copy()
    for _ in range(passes):
        smoothed = gaussian_filter1d(smoothed, sigma=window/6, mode='nearest')
    return smoothed

def compute_mean_and_se(data_list, max_timesteps=3000):
    """Compute mean and standard error across seeds"""
    # Stack all seeds
    data_array = np.array([d[:max_timesteps] for d in data_list])
    
    mean = np.mean(data_array, axis=0)
    std = np.std(data_array, axis=0)
    se = std / np.sqrt(len(data_list))
    
    timesteps = np.arange(1, max_timesteps + 1)
    
    return mean, se, timesteps

def plot_timestep_comparison(env_name, max_timesteps=3000, smooth_window=400):
    """Create timestep-based comparison plot"""
    print("\nProcessing {}...".format(env_name))
    
    # Load PSRL data
    psrl_with_data = []
    psrl_without_data = []
    for seed in range(5):
        data = load_and_interpolate_timestep_data(
            'seeds_data/{}_timestep_rewards_with_oracle_seed{}.txt'.format(env_name, seed),
            max_timesteps
        )
        psrl_with_data.append(data)
        
        data = load_and_interpolate_timestep_data(
            'seeds_data/{}_timestep_rewards_without_oracle_seed{}.txt'.format(env_name, seed),
            max_timesteps
        )
        psrl_without_data.append(data)
    
    # Load PETS data
    pets_data = []
    for seed in range(5):
        data = load_and_interpolate_timestep_data(
            'seeds_data/pets_{}_timestep_rewards_seed{}.txt'.format(env_name, seed),
            max_timesteps
        )
        pets_data.append(data)
    
    print("  Loaded 5 seeds for each algorithm")
    
    # Smooth data
    psrl_with_smooth = [smooth_data(d, window=smooth_window, passes=2) for d in psrl_with_data]
    psrl_without_smooth = [smooth_data(d, window=smooth_window, passes=2) for d in psrl_without_data]
    pets_smooth = [smooth_data(d, window=smooth_window, passes=2) for d in pets_data]
    
    # Compute mean and SE
    psrl_with_mean, psrl_with_se, timesteps = compute_mean_and_se(psrl_with_smooth, max_timesteps)
    psrl_without_mean, psrl_without_se, _ = compute_mean_and_se(psrl_without_smooth, max_timesteps)
    pets_mean, pets_se, _ = compute_mean_and_se(pets_smooth, max_timesteps)
    
    # Create plot
    fig, ax = plt.subplots(figsize=(12, 7))
    
    # Plot PSRL WITH oracle
    ax.plot(timesteps, psrl_with_mean, 'b-', linewidth=2.5, label='PSRL (with oracle)', alpha=0.9)
    ax.fill_between(timesteps, 
                     psrl_with_mean - psrl_with_se, 
                     psrl_with_mean + psrl_with_se,
                     color='b', alpha=0.2)
    
    # Plot PSRL WITHOUT oracle
    ax.plot(timesteps, psrl_without_mean, 'g-', linewidth=2.5, label='PSRL (without oracle)', alpha=0.9)
    ax.fill_between(timesteps,
                     psrl_without_mean - psrl_without_se,
                     psrl_without_mean + psrl_without_se,
                     color='g', alpha=0.2)
    
    # Plot PETS
    ax.plot(timesteps, pets_mean, 'r-', linewidth=2.5, label='PETS', alpha=0.9)
    ax.fill_between(timesteps,
                     pets_mean - pets_se,
                     pets_mean + pets_se,
                     color='r', alpha=0.2)
    
    # Formatting
    ax.set_xlabel('Time Steps', fontsize=14, fontweight='bold')
    ax.set_ylabel('Cumulative Reward', fontsize=14, fontweight='bold')
    ax.set_title('{} - Learning Curves (3000 Timesteps)'.format(env_name.capitalize()), 
                 fontsize=16, fontweight='bold')
    ax.legend(loc='best', fontsize=12, framealpha=0.95, edgecolor='black')
    ax.grid(True, alpha=0.3, linestyle='--')
    ax.tick_params(labelsize=11)
    
    # Set x-axis to show nice intervals
    ax.set_xlim(0, max_timesteps)
    ax.set_xticks(np.arange(0, max_timesteps + 1, 500))
    
    # Save plots
    plt.tight_layout()
    plt.savefig('{}_timestep_comparison.png'.format(env_name), dpi=300, bbox_inches='tight')
    plt.savefig('{}_timestep_comparison.svg'.format(env_name), bbox_inches='tight')
    print("  Saved: {}_timestep_comparison.png and .svg".format(env_name))
    
    # Print summary at key timesteps
    print("\n  Cumulative rewards at key timesteps:")
    for ts in [1000, 2000, 3000]:
        idx = ts - 1
        print("    Timestep {}:".format(ts))
        print("      PSRL (with oracle):    {:.1f} +/- {:.1f}".format(
            psrl_with_mean[idx], psrl_with_se[idx]))
        print("      PSRL (without oracle): {:.1f} +/- {:.1f}".format(
            psrl_without_mean[idx], psrl_without_se[idx]))
        print("      PETS:                  {:.1f} +/- {:.1f}".format(
            pets_mean[idx], pets_se[idx]))
    
    plt.close()

if __name__ == '__main__':
    print("="*70)
    print(" "*15 + "Timestep-Based Comparison Plots")
    print("="*70)
    
    # CartPole - 3000 timesteps
    plot_timestep_comparison('cartpole', max_timesteps=3000, smooth_window=400)
    
    # Pendulum - 3000 timesteps
    plot_timestep_comparison('pendulum', max_timesteps=3000, smooth_window=400)
    
    print("\n" + "="*70)
    print(" "*20 + "Plots Generated Successfully!")
    print("="*70)
