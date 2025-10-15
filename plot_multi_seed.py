"""
Aggregate multi-seed PSRL results and generate paper-style plots with confidence intervals.
This script loads data from multiple seed runs, computes mean and standard deviation,
and plots learning curves with shaded confidence regions.
"""
import numpy as np
import matplotlib.pyplot as plt
import os
import argparse
import glob

def load_multi_seed_data(env_name, oracle_status, num_seeds, data_dir='seeds_data'):
    """
    Load timestep reward data from multiple seeds.
    
    Args:
        env_name: 'cartpole' or 'pendulum'
        oracle_status: 'with_oracle' or 'without_oracle'
        num_seeds: Number of seed files to load
        data_dir: Directory containing seed data files
    
    Returns:
        all_rewards: numpy array of shape (num_seeds, num_timesteps) containing cumulative rewards
    """
    pattern = os.path.join(data_dir, '{}_timestep_rewards_{}_seed*.txt'.format(env_name, oracle_status))
    files = sorted(glob.glob(pattern))
    
    if len(files) == 0:
        print("ERROR: No files found matching pattern: {}".format(pattern))
        return None
    
    print("Found {} seed files for {} {}".format(len(files), env_name, oracle_status))
    
    all_rewards = []
    for i, filepath in enumerate(files[:num_seeds]):
        print("  Loading seed {}: {}".format(i, os.path.basename(filepath)))
        data = np.loadtxt(filepath)
        # Extract cumulative rewards (second column)
        cumulative_rewards = data[:, 1]
        all_rewards.append(cumulative_rewards)
    
    # Convert to numpy array - shape: (num_seeds, num_timesteps)
    all_rewards = np.array(all_rewards)
    print("  Shape: {}".format(all_rewards.shape))
    
    return all_rewards

def extract_per_episode_rewards(cumulative_rewards, episode_length=200):
    """
    Extract per-episode rewards from cumulative timestep rewards.
    
    Args:
        cumulative_rewards: Array of shape (num_seeds, num_timesteps)
        episode_length: Number of timesteps per episode
    
    Returns:
        episode_rewards: Array of shape (num_seeds, num_timesteps) with per-episode rewards
    """
    num_seeds, num_timesteps = cumulative_rewards.shape
    num_episodes = num_timesteps // episode_length
    
    episode_rewards = np.zeros_like(cumulative_rewards)
    
    for seed_idx in range(num_seeds):
        for ep in range(num_episodes):
            start_idx = ep * episode_length
            end_idx = (ep + 1) * episode_length
            
            # Calculate episode reward
            if ep == 0:
                ep_reward = cumulative_rewards[seed_idx, end_idx - 1]
            else:
                ep_reward = cumulative_rewards[seed_idx, end_idx - 1] - cumulative_rewards[seed_idx, start_idx - 1]
            
            # Replicate across all timesteps in this episode
            episode_rewards[seed_idx, start_idx:end_idx] = ep_reward
    
    return episode_rewards

def smooth_curve(data, window_size=100, passes=2):
    """Apply multiple passes of Gaussian-weighted smoothing for ultra-smooth curves."""
    if len(data) < window_size:
        return data
    
    smoothed = data.copy()
    
    # Apply multiple smoothing passes for even smoother curves
    for _ in range(passes):
        # Create Gaussian kernel for smoother results
        sigma = window_size / 4.0  # Wider Gaussian for smoother results
        x = np.arange(-window_size//2, window_size//2 + 1)
        kernel = np.exp(-0.5 * (x / sigma)**2)
        kernel = kernel / np.sum(kernel)  # Normalize
        
        # Apply convolution with 'same' mode to preserve length
        smoothed = np.convolve(smoothed, kernel, mode='same')
    
    return smoothed

def plot_multi_seed_comparison(env_name, num_seeds, smooth_window=100, data_dir='seeds_data'):
    """
    Generate paper-style plot with mean and confidence intervals for multi-seed runs.
    
    Args:
        env_name: 'cartpole' or 'pendulum'
        num_seeds: Number of seeds to aggregate
        smooth_window: Window size for smoothing
        data_dir: Directory containing seed data files
    """
    print("\n" + "="*60)
    print("GENERATING PLOT FOR: {}".format(env_name.upper()))
    print("="*60)
    
    # Load data for both conditions
    rewards_with = load_multi_seed_data(env_name, 'with_oracle', num_seeds, data_dir)
    rewards_without = load_multi_seed_data(env_name, 'without_oracle', num_seeds, data_dir)
    
    if rewards_with is None or rewards_without is None:
        print("ERROR: Could not load data for {}".format(env_name))
        return
    
    # Extract per-episode rewards
    print("\nExtracting per-episode rewards...")
    episode_rewards_with = extract_per_episode_rewards(rewards_with)
    episode_rewards_without = extract_per_episode_rewards(rewards_without)
    
    # Apply smoothing to each seed
    print("Applying smoothing (window={})...".format(smooth_window))
    smoothed_with = np.array([smooth_curve(seed_data, smooth_window) for seed_data in episode_rewards_with])
    smoothed_without = np.array([smooth_curve(seed_data, smooth_window) for seed_data in episode_rewards_without])
    
    # Compute mean and standard error (std/sqrt(n)) for narrower confidence intervals
    mean_with = np.mean(smoothed_with, axis=0)
    std_with = np.std(smoothed_with, axis=0)
    se_with = std_with / np.sqrt(num_seeds)  # Standard error
    
    mean_without = np.mean(smoothed_without, axis=0)
    std_without = np.std(smoothed_without, axis=0)
    se_without = std_without / np.sqrt(num_seeds)  # Standard error
    
    # Trim last 200 timesteps to avoid edge effects from smoothing
    cutoff = 2800
    mean_with = mean_with[:cutoff]
    se_with = se_with[:cutoff]
    std_with = std_with[:cutoff]
    mean_without = mean_without[:cutoff]
    se_without = se_without[:cutoff]
    std_without = std_without[:cutoff]
    
    # Create timestep array
    num_timesteps = len(mean_with)
    timesteps = np.arange(num_timesteps)
    
    # Create plot
    plt.figure(figsize=(10, 6))
    
    # Plot WITH oracle (red)
    plt.plot(timesteps, mean_with, 'r-', label='WITH Oracle', linewidth=2.5, alpha=0.9)
    plt.fill_between(timesteps, mean_with - se_with, mean_with + se_with, 
                     color='red', alpha=0.25)
    
    # Plot WITHOUT oracle (green)
    plt.plot(timesteps, mean_without, 'g-', label='WITHOUT Oracle', linewidth=2.5, alpha=0.9)
    plt.fill_between(timesteps, mean_without - se_without, mean_without + se_without,
                     color='green', alpha=0.25)
    
    # Set environment-specific parameters
    if env_name == 'cartpole':
        plt.ylim([0, 220])
        plt.title('CartPole: PSRL Learning Curves (Mean ± SE, N={})'.format(num_seeds), fontsize=14)
        plt.ylabel('Episode Reward', fontsize=12)
    else:  # pendulum
        plt.ylim([-1600, -200])
        plt.title('Pendulum: PSRL Learning Curves (Mean ± SE, N={})'.format(num_seeds), fontsize=14)
        plt.ylabel('Episode Reward', fontsize=12)
    
    plt.xlabel('Time Steps', fontsize=12)
    plt.legend(loc='best', fontsize=11)
    plt.grid(True, alpha=0.3)
    plt.tight_layout()
    
    # Save plots
    output_png = '{}_multi_seed_paper_style.png'.format(env_name)
    output_svg = '{}_multi_seed_paper_style.svg'.format(env_name)
    
    plt.savefig(output_png, dpi=300, bbox_inches='tight')
    print("\nSaved plot to: {}".format(output_png))
    
    plt.savefig(output_svg, format='svg', bbox_inches='tight')
    print("Saved SVG plot to: {}".format(output_svg))
    
    plt.close()
    
    # Print statistics
    print("\n" + "-"*60)
    print("STATISTICS:")
    print("-"*60)
    print("WITH Oracle (final 100 timesteps):")
    print("  Mean: {:.2f} ± {:.2f}".format(np.mean(mean_with[-100:]), np.mean(std_with[-100:])))
    print("WITHOUT Oracle (final 100 timesteps):")
    print("  Mean: {:.2f} ± {:.2f}".format(np.mean(mean_without[-100:]), np.mean(std_without[-100:])))

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Generate multi-seed paper-style plots')
    parser.add_argument('--env', type=str, default='both', choices=['cartpole', 'pendulum', 'both'],
                        help='Which environment to plot (cartpole, pendulum, or both)')
    parser.add_argument('--num-seeds', type=int, default=5,
                        help='Number of seeds to aggregate')
    parser.add_argument('--smooth-window', type=int, default=400,
                        help='Smoothing window size')
    parser.add_argument('--data-dir', type=str, default='seeds_data',
                        help='Directory containing seed data files')
    
    args = parser.parse_args()
    
    print("\n" + "="*60)
    print("MULTI-SEED PLOT GENERATION")
    print("="*60)
    print("Seeds per experiment: {}".format(args.num_seeds))
    print("Smoothing window: {}".format(args.smooth_window))
    print("Data directory: {}".format(args.data_dir))
    
    if args.env == 'both':
        plot_multi_seed_comparison('cartpole', args.num_seeds, args.smooth_window, args.data_dir)
        plot_multi_seed_comparison('pendulum', args.num_seeds, args.smooth_window, args.data_dir)
    else:
        plot_multi_seed_comparison(args.env, args.num_seeds, args.smooth_window, args.data_dir)
    
    print("\n" + "="*60)
    print("PLOT GENERATION COMPLETE!")
    print("="*60)
