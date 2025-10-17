"""
Extended PETS comparison: Show how many episodes PETS needs to match PSRL's Episode 14 performance
This demonstrates the learning efficiency difference between PSRL and PETS
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

def smooth_data(data, window=5, passes=2):
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

def plot_extended_comparison(env_name):
    """Create extended comparison plot showing PETS full learning curve"""
    print("\nProcessing {}...".format(env_name))
    
    # Load PSRL WITH oracle data (15 episodes)
    psrl_with_rewards = []
    for seed in range(5):
        _, rewards = load_episode_rewards('seeds_data/{}_log_with_oracle_seed{}.txt'.format(env_name, seed))
        psrl_with_rewards.append(rewards)
    
    # Load PSRL WITHOUT oracle data (15 episodes)
    psrl_without_rewards = []
    for seed in range(5):
        _, rewards = load_episode_rewards('seeds_data/{}_log_without_oracle_seed{}.txt'.format(env_name, seed))
        psrl_without_rewards.append(rewards)
    
    # Load PETS data (100 episodes)
    pets_rewards = []
    for seed in range(5):
        _, rewards = load_episode_rewards('seeds_data/pets_{}_log_seed{}.txt'.format(env_name, seed))
        pets_rewards.append(rewards)
    
    # Get max episodes for each
    max_ep_psrl_with = min(len(r) for r in psrl_with_rewards)
    max_ep_psrl_without = min(len(r) for r in psrl_without_rewards)
    max_ep_pets = min(len(r) for r in pets_rewards)
    
    print("  PSRL WITH episodes: {}, PSRL WITHOUT episodes: {}, PETS episodes: {}".format(
        max_ep_psrl_with, max_ep_psrl_without, max_ep_pets))
    
    # Smooth data
    psrl_with_smooth = [smooth_data(r, window=3, passes=2) for r in psrl_with_rewards]
    psrl_without_smooth = [smooth_data(r, window=3, passes=2) for r in psrl_without_rewards]
    pets_smooth = [smooth_data(r, window=5, passes=2) for r in pets_rewards]
    
    # Compute mean and SE for PSRL (15 episodes)
    psrl_with_mean, psrl_with_se, episodes_psrl = compute_mean_and_se(psrl_with_smooth, max_ep_psrl_with)
    psrl_without_mean, psrl_without_se, _ = compute_mean_and_se(psrl_without_smooth, max_ep_psrl_without)
    
    # Compute mean and SE for PETS (all 100 episodes)
    pets_mean, pets_se, episodes_pets = compute_mean_and_se(pets_smooth, max_ep_pets)
    
    # Get PSRL episode 14 performance (target)
    psrl_with_target = psrl_with_mean[14] if len(psrl_with_mean) > 14 else psrl_with_mean[-1]
    psrl_without_target = psrl_without_mean[14] if len(psrl_without_mean) > 14 else psrl_without_mean[-1]
    
    # Find where PETS crosses these thresholds
    pets_crosses_with = np.where(pets_mean >= psrl_with_target)[0]
    pets_crosses_without = np.where(pets_mean >= psrl_without_target)[0]
    
    # Create figure with two subplots
    fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(12, 10))
    
    # ========== TOP PLOT: First 15 episodes comparison ==========
    ax1.plot(episodes_psrl[:15], psrl_with_mean[:15], 'b-', linewidth=2.5, 
             label='PSRL (with oracle)', alpha=0.9)
    ax1.fill_between(episodes_psrl[:15], 
                      psrl_with_mean[:15] - psrl_with_se[:15], 
                      psrl_with_mean[:15] + psrl_with_se[:15],
                      color='b', alpha=0.2)
    
    ax1.plot(episodes_psrl[:15], psrl_without_mean[:15], 'g-', linewidth=2.5,
             label='PSRL (without oracle)', alpha=0.9)
    ax1.fill_between(episodes_psrl[:15],
                      psrl_without_mean[:15] - psrl_without_se[:15],
                      psrl_without_mean[:15] + psrl_without_se[:15],
                      color='g', alpha=0.2)
    
    ax1.plot(episodes_pets[:15], pets_mean[:15], 'r-', linewidth=2.5,
             label='PETS', alpha=0.9)
    ax1.fill_between(episodes_pets[:15],
                      pets_mean[:15] - pets_se[:15],
                      pets_mean[:15] + pets_se[:15],
                      color='r', alpha=0.2)
    
    ax1.set_xlabel('Episode', fontsize=12, fontweight='bold')
    ax1.set_ylabel('Average Reward', fontsize=12, fontweight='bold')
    ax1.set_title('{} - First 15 Episodes Comparison'.format(env_name.capitalize()), 
                  fontsize=14, fontweight='bold')
    ax1.legend(loc='best', fontsize=11, framealpha=0.95, edgecolor='black')
    ax1.grid(True, alpha=0.3, linestyle='--')
    ax1.tick_params(labelsize=10)
    
    # ========== BOTTOM PLOT: Extended PETS learning (all 100 episodes) ==========
    ax2.plot(episodes_pets, pets_mean, 'r-', linewidth=2.5, label='PETS (full 100 episodes)', alpha=0.9)
    ax2.fill_between(episodes_pets,
                      pets_mean - pets_se,
                      pets_mean + pets_se,
                      color='r', alpha=0.2)
    
    # Draw horizontal lines for PSRL Episode 14 performance
    ax2.axhline(y=psrl_with_target, color='b', linestyle='--', linewidth=2, 
                label='PSRL WITH oracle Episode 14: {:.1f}'.format(psrl_with_target), alpha=0.7)
    ax2.axhline(y=psrl_without_target, color='g', linestyle='--', linewidth=2,
                label='PSRL WITHOUT oracle Episode 14: {:.1f}'.format(psrl_without_target), alpha=0.7)
    
    # Mark where PETS crosses the thresholds
    if len(pets_crosses_with) > 0:
        cross_ep_with = pets_crosses_with[0]
        ax2.axvline(x=cross_ep_with, color='b', linestyle=':', linewidth=1.5, alpha=0.5)
        ax2.plot(cross_ep_with, pets_mean[cross_ep_with], 'bo', markersize=10, 
                label='PETS reaches PSRL WITH at Episode {}'.format(cross_ep_with))
        print("  PETS reaches PSRL WITH oracle performance at Episode: {}".format(cross_ep_with))
    else:
        print("  PETS never reaches PSRL WITH oracle Episode 14 performance ({:.1f})".format(psrl_with_target))
        print("  PETS maximum: {:.1f} at episode {}".format(pets_mean.max(), pets_mean.argmax()))
    
    if len(pets_crosses_without) > 0:
        cross_ep_without = pets_crosses_without[0]
        ax2.axvline(x=cross_ep_without, color='g', linestyle=':', linewidth=1.5, alpha=0.5)
        ax2.plot(cross_ep_without, pets_mean[cross_ep_without], 'go', markersize=10,
                label='PETS reaches PSRL WITHOUT at Episode {}'.format(cross_ep_without))
        print("  PETS reaches PSRL WITHOUT oracle performance at Episode: {}".format(cross_ep_without))
    else:
        print("  PETS never reaches PSRL WITHOUT oracle Episode 14 performance ({:.1f})".format(psrl_without_target))
    
    ax2.set_xlabel('Episode', fontsize=12, fontweight='bold')
    ax2.set_ylabel('Average Reward', fontsize=12, fontweight='bold')
    ax2.set_title('{} - PETS Extended Learning (100 Episodes)'.format(env_name.capitalize()), 
                  fontsize=14, fontweight='bold')
    ax2.legend(loc='best', fontsize=10, framealpha=0.95, edgecolor='black')
    ax2.grid(True, alpha=0.3, linestyle='--')
    ax2.tick_params(labelsize=10)
    ax2.set_xlim(0, max_ep_pets)
    
    # Save plots
    plt.tight_layout()
    plt.savefig('{}_pets_extended_comparison.png'.format(env_name), dpi=300, bbox_inches='tight')
    plt.savefig('{}_pets_extended_comparison.svg'.format(env_name), bbox_inches='tight')
    print("  Saved: {}_pets_extended_comparison.png and .svg".format(env_name))
    
    # Print summary statistics
    print("\n  Performance Summary:")
    print("    PSRL WITH oracle Episode 14:    {:.1f} +/- {:.1f}".format(
        psrl_with_mean[14], psrl_with_se[14]))
    print("    PSRL WITHOUT oracle Episode 14: {:.1f} +/- {:.1f}".format(
        psrl_without_mean[14], psrl_without_se[14]))
    print("    PETS Episode 14:                {:.1f} +/- {:.1f}".format(
        pets_mean[14], pets_se[14]))
    print("    PETS Episode {}:                {:.1f} +/- {:.1f}".format(
        max_ep_pets-1, pets_mean[-1], pets_se[-1]))
    print("    PETS Maximum:                   {:.1f} at episode {}".format(
        pets_mean.max(), pets_mean.argmax()))
    
    plt.close()

if __name__ == '__main__':
    print("="*70)
    print(" "*10 + "PETS Extended Comparison: Episode Efficiency Analysis")
    print("="*70)
    
    # CartPole - compare all 100 PETS episodes
    plot_extended_comparison('cartpole')
    
    # Pendulum - compare all 15 PETS episodes (same as PSRL)
    plot_extended_comparison('pendulum')
    
    print("\n" + "="*70)
    print(" "*20 + "Analysis Complete!")
    print("="*70)
