"""
Generate summary tables for PETS experiment rewards
Shows episode-by-episode rewards for all seeds
"""

import numpy as np
import pandas as pd

def load_episode_rewards(filename):
    """Load episode rewards from log file"""
    data = np.loadtxt(filename)
    episodes = data[:, 0].astype(int)
    rewards = data[:, 1]
    return episodes, rewards

def create_pets_summary_tables():
    """Create comprehensive summary tables for PETS experiments"""
    
    print("="*100)
    print(" "*35 + "PETS EXPERIMENT RESULTS")
    print("="*100)
    
    # ==================== CARTPOLE ====================
    print("\n" + "="*100)
    print(" "*40 + "CARTPOLE (100 EPISODES)")
    print("="*100)
    
    # Load all CartPole seeds
    cartpole_data = {}
    for seed in range(5):
        episodes, rewards = load_episode_rewards('seeds_data/pets_cartpole_log_seed{}.txt'.format(seed))
        cartpole_data['Seed {}'.format(seed)] = rewards
    
    # Create DataFrame
    max_episodes = max(len(v) for v in cartpole_data.values())
    
    # Show first 20 episodes in detail
    print("\nFirst 20 Episodes (detailed):")
    print("-"*100)
    df_cartpole_first20 = pd.DataFrame({k: v[:20] for k, v in cartpole_data.items()})
    df_cartpole_first20['Episode'] = range(len(df_cartpole_first20))
    df_cartpole_first20 = df_cartpole_first20[['Episode', 'Seed 0', 'Seed 1', 'Seed 2', 'Seed 3', 'Seed 4']]
    df_cartpole_first20['Mean'] = df_cartpole_first20[['Seed 0', 'Seed 1', 'Seed 2', 'Seed 3', 'Seed 4']].mean(axis=1)
    df_cartpole_first20['Std'] = df_cartpole_first20[['Seed 0', 'Seed 1', 'Seed 2', 'Seed 3', 'Seed 4']].std(axis=1)
    print(df_cartpole_first20.to_string(index=False, float_format='%.2f'))
    
    # Show every 10th episode for full view
    print("\n\nEvery 10th Episode (full 100 episodes):")
    print("-"*100)
    episode_indices = list(range(0, 100, 10)) + [99]  # 0, 10, 20, ..., 90, 99
    df_cartpole_every10 = pd.DataFrame()
    df_cartpole_every10['Episode'] = episode_indices
    for seed in range(5):
        df_cartpole_every10['Seed {}'.format(seed)] = [cartpole_data['Seed {}'.format(seed)][i] for i in episode_indices]
    df_cartpole_every10['Mean'] = df_cartpole_every10[['Seed 0', 'Seed 1', 'Seed 2', 'Seed 3', 'Seed 4']].mean(axis=1)
    df_cartpole_every10['Std'] = df_cartpole_every10[['Seed 0', 'Seed 1', 'Seed 2', 'Seed 3', 'Seed 4']].std(axis=1)
    print(df_cartpole_every10.to_string(index=False, float_format='%.2f'))
    
    # Statistics summary
    print("\n\nCartPole Statistics Summary:")
    print("-"*100)
    stats_data = []
    for seed in range(5):
        rewards = cartpole_data['Seed {}'.format(seed)]
        stats_data.append({
            'Seed': seed,
            'Episodes': len(rewards),
            'Mean Reward': np.mean(rewards),
            'Std Reward': np.std(rewards),
            'Min Reward': np.min(rewards),
            'Max Reward': np.max(rewards),
            'First 10 Mean': np.mean(rewards[:10]),
            'Last 10 Mean': np.mean(rewards[-10:])
        })
    
    df_stats = pd.DataFrame(stats_data)
    print(df_stats.to_string(index=False, float_format='%.2f'))
    
    # Overall statistics
    all_rewards = np.concatenate([cartpole_data['Seed {}'.format(i)] for i in range(5)])
    print("\n\nOverall CartPole Statistics (all seeds combined):")
    print("-"*100)
    print("Total episodes: {}".format(len(all_rewards)))
    print("Mean reward: {:.2f} ± {:.2f}".format(np.mean(all_rewards), np.std(all_rewards)))
    print("Min reward: {:.2f}".format(np.min(all_rewards)))
    print("Max reward: {:.2f}".format(np.max(all_rewards)))
    print("Median reward: {:.2f}".format(np.median(all_rewards)))
    
    # ==================== PENDULUM ====================
    print("\n\n" + "="*100)
    print(" "*40 + "PENDULUM (15 EPISODES)")
    print("="*100)
    
    # Load all Pendulum seeds
    pendulum_data = {}
    for seed in range(5):
        episodes, rewards = load_episode_rewards('seeds_data/pets_pendulum_log_seed{}.txt'.format(seed))
        pendulum_data['Seed {}'.format(seed)] = rewards
    
    # Create DataFrame for all 15 episodes
    print("\nAll 15 Episodes:")
    print("-"*100)
    df_pendulum = pd.DataFrame({k: v for k, v in pendulum_data.items()})
    df_pendulum['Episode'] = range(len(df_pendulum))
    df_pendulum = df_pendulum[['Episode', 'Seed 0', 'Seed 1', 'Seed 2', 'Seed 3', 'Seed 4']]
    df_pendulum['Mean'] = df_pendulum[['Seed 0', 'Seed 1', 'Seed 2', 'Seed 3', 'Seed 4']].mean(axis=1)
    df_pendulum['Std'] = df_pendulum[['Seed 0', 'Seed 1', 'Seed 2', 'Seed 3', 'Seed 4']].std(axis=1)
    print(df_pendulum.to_string(index=False, float_format='%.2f'))
    
    # Statistics summary
    print("\n\nPendulum Statistics Summary:")
    print("-"*100)
    stats_data = []
    for seed in range(5):
        rewards = pendulum_data['Seed {}'.format(seed)]
        stats_data.append({
            'Seed': seed,
            'Episodes': len(rewards),
            'Mean Reward': np.mean(rewards),
            'Std Reward': np.std(rewards),
            'Min Reward': np.min(rewards),
            'Max Reward': np.max(rewards),
            'First 5 Mean': np.mean(rewards[:5]),
            'Last 5 Mean': np.mean(rewards[-5:])
        })
    
    df_stats = pd.DataFrame(stats_data)
    print(df_stats.to_string(index=False, float_format='%.2f'))
    
    # Overall statistics
    all_rewards = np.concatenate([pendulum_data['Seed {}'.format(i)] for i in range(5)])
    print("\n\nOverall Pendulum Statistics (all seeds combined):")
    print("-"*100)
    print("Total episodes: {}".format(len(all_rewards)))
    print("Mean reward: {:.2f} ± {:.2f}".format(np.mean(all_rewards), np.std(all_rewards)))
    print("Min reward: {:.2f}".format(np.min(all_rewards)))
    print("Max reward: {:.2f}".format(np.max(all_rewards)))
    print("Median reward: {:.2f}".format(np.median(all_rewards)))
    
    # ==================== COMPARISON WITH PSRL ====================
    print("\n\n" + "="*100)
    print(" "*30 + "COMPARISON: PETS vs PSRL AT EPISODE 14")
    print("="*100)
    
    # Load PSRL data for comparison
    psrl_with_cartpole = []
    psrl_without_cartpole = []
    psrl_with_pendulum = []
    psrl_without_pendulum = []
    
    for seed in range(5):
        _, rewards = load_episode_rewards('seeds_data/cartpole_log_with_oracle_seed{}.txt'.format(seed))
        psrl_with_cartpole.append(rewards[14] if len(rewards) > 14 else rewards[-1])
        
        _, rewards = load_episode_rewards('seeds_data/cartpole_log_without_oracle_seed{}.txt'.format(seed))
        psrl_without_cartpole.append(rewards[14] if len(rewards) > 14 else rewards[-1])
        
        _, rewards = load_episode_rewards('seeds_data/pendulum_log_with_oracle_seed{}.txt'.format(seed))
        psrl_with_pendulum.append(rewards[14] if len(rewards) > 14 else rewards[-1])
        
        _, rewards = load_episode_rewards('seeds_data/pendulum_log_without_oracle_seed{}.txt'.format(seed))
        psrl_without_pendulum.append(rewards[14] if len(rewards) > 14 else rewards[-1])
    
    # CartPole comparison
    pets_cartpole_ep14 = [cartpole_data['Seed {}'.format(i)][14] for i in range(5)]
    
    print("\nCartPole Episode 14 Performance:")
    print("-"*100)
    comparison_data = {
        'Algorithm': ['PSRL (with oracle)', 'PSRL (without oracle)', 'PETS'],
        'Mean': [np.mean(psrl_with_cartpole), np.mean(psrl_without_cartpole), np.mean(pets_cartpole_ep14)],
        'Std': [np.std(psrl_with_cartpole), np.std(psrl_without_cartpole), np.std(pets_cartpole_ep14)],
        'Min': [np.min(psrl_with_cartpole), np.min(psrl_without_cartpole), np.min(pets_cartpole_ep14)],
        'Max': [np.max(psrl_with_cartpole), np.max(psrl_without_cartpole), np.max(pets_cartpole_ep14)]
    }
    df_comparison = pd.DataFrame(comparison_data)
    print(df_comparison.to_string(index=False, float_format='%.2f'))
    
    # Pendulum comparison
    pets_pendulum_ep14 = [pendulum_data['Seed {}'.format(i)][14] for i in range(5)]
    
    print("\n\nPendulum Episode 14 Performance:")
    print("-"*100)
    comparison_data = {
        'Algorithm': ['PSRL (with oracle)', 'PSRL (without oracle)', 'PETS'],
        'Mean': [np.mean(psrl_with_pendulum), np.mean(psrl_without_pendulum), np.mean(pets_pendulum_ep14)],
        'Std': [np.std(psrl_with_pendulum), np.std(psrl_without_pendulum), np.std(pets_pendulum_ep14)],
        'Min': [np.min(psrl_with_pendulum), np.min(psrl_without_pendulum), np.min(pets_pendulum_ep14)],
        'Max': [np.max(psrl_with_pendulum), np.max(psrl_without_pendulum), np.max(pets_pendulum_ep14)]
    }
    df_comparison = pd.DataFrame(comparison_data)
    print(df_comparison.to_string(index=False, float_format='%.2f'))
    
    print("\n" + "="*100)
    print(" "*35 + "END OF REPORT")
    print("="*100)

if __name__ == '__main__':
    create_pets_summary_tables()
