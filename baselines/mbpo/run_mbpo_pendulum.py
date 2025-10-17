"""
MBPO for Pendulum environment

Simplified Model-Based Policy Optimization using learned dynamics model
and policy network trained on both real and synthetic data.
"""

import numpy as np
import torch
import argparse
import os
import sys

# Add parent directory to path
sys.path.append(os.path.dirname(os.path.dirname(os.path.dirname(__file__))))

from pendulum_gym import PendulumEnv
from NB_dx_tf import neural_bays_dx_tf
from tf_models.constructor import construct_model
from simple_mbpo import SimplifiedMBPO

os.environ["CUDA_VISIBLE_DEVICES"] = "0"
os.environ['KMP_DUPLICATE_LIB_OK'] = 'True'


def run_mbpo_pendulum(args):
    """Run MBPO on Pendulum environment"""
    
    # Set random seeds
    np.random.seed(args.seed)
    torch.manual_seed(args.seed)
    
    # Create environment
    env = PendulumEnv()
    obs_shape = env.observation_space.shape[0]
    action_shape = env.action_space.shape[0]
    action_low = env.action_space.low
    action_high = env.action_space.high
    
    print("="*70)
    print("MBPO Pendulum")
    print("="*70)
    print("State dim: {}, Action dim: {}".format(obs_shape, action_shape))
    print("Action bounds: [{:.2f}, {:.2f}]".format(action_low[0], action_high[0]))
    print("Seed: {}".format(args.seed))
    print("Episodes: {}".format(args.num_episodes))
    print("="*70)
    
    # Create dynamics model
    dx_model = construct_model(obs_dim=obs_shape, act_dim=action_shape, 
                               hidden_dim=200, num_networks=1, num_elites=1)
    
    my_dx = neural_bays_dx_tf(args, dx_model, "dx", obs_shape, 
                              sigma_n2=args.sigma_n**2, sigma2=args.sigma**2)
    
    # Create MBPO agent
    mbpo = SimplifiedMBPO(
        state_dim=obs_shape,
        action_dim=action_shape,
        action_low=action_low,
        action_high=action_high,
        dynamics_model=my_dx,
        hidden_dim=args.policy_hidden_dim,
        lr=args.policy_lr,
        gamma=args.gamma,
        env_name='pendulum'
    )
    
    # Logging
    episode_rewards = []
    timestep_rewards = []
    cumulative_reward = 0
    total_timesteps = 0
    
    # Output directory
    output_dir = args.output_dir
    os.makedirs(output_dir, exist_ok=True)
    seed_suffix = '_seed{}'.format(args.seed) if args.seed >= 0 else ''
    log_file = os.path.join(output_dir, 'mbpo_pendulum_log' + seed_suffix + '.txt')
    timestep_file = os.path.join(output_dir, 'mbpo_pendulum_timestep_rewards' + seed_suffix + '.txt')
    
    # Training loop
    for episode in range(args.num_episodes):
        state = env.reset()
        state = state.squeeze() if hasattr(state, 'squeeze') else state
        episode_reward = 0
        episode_length = 0
        
        # Sample from dynamics model for this episode
        my_dx.sample()
        
        for step in range(args.max_steps):
            # Select action (more exploration in early episodes)
            if episode == 0 and total_timesteps < 50:
                # Random exploration for first episode
                action = env.action_space.sample()
            else:
                # Use policy with exploration noise
                action = mbpo.select_action(state, deterministic=False)
            
            # Execute action
            next_state, reward, done, _ = env.step(action)
            next_state = next_state.squeeze() if hasattr(next_state, 'squeeze') else next_state
            
            # Store transition
            mbpo.add_real_transition(state, action, reward, next_state, done)
            
            # Train dynamics model
            xu = torch.cat([torch.tensor(state).double(), torch.tensor(action).double()])
            my_dx.add_data(new_x=xu, new_y=torch.tensor(next_state - state))
            
            episode_reward += reward
            cumulative_reward += reward
            total_timesteps += 1
            episode_length += 1
            
            # Log timestep reward
            timestep_rewards.append([total_timesteps, cumulative_reward])
            
            state = next_state
            
            if done:
                break
        
        # Train dynamics model after episode
        if episode > 0:
            my_dx.train(epochs=args.training_iter_dx)
            my_dx.update_bays_reg()
        
        # Generate model rollouts and train policy (after episode 1)
        if episode >= 1:
            # Generate synthetic data
            mbpo.generate_model_rollouts(
                num_rollouts=args.num_model_rollouts,
                rollout_length=args.rollout_length
            )
            
            # Train policy on real + synthetic data
            mbpo.train_policy(num_updates=args.policy_updates_per_episode)
            
            # Decay exploration noise
            mbpo.decrease_noise(factor=0.98)
        
        # Log episode
        episode_rewards.append([episode, episode_reward])
        print("Episode {:3d}: Reward = {:7.2f}, Length = {:3d}, Timesteps = {:4d}".format(
            episode, episode_reward, episode_length, total_timesteps))
        
        # Save logs
        np.savetxt(log_file, episode_rewards, fmt='%d %.6f')
        np.savetxt(timestep_file, timestep_rewards, fmt='%d %.18e')
    
    print("\n" + "="*70)
    print("Training Complete!")
    print("Total timesteps: {}".format(total_timesteps))
    print("Final 5 episode mean: {:.2f}".format(np.mean([r[1] for r in episode_rewards[-5:]])))
    print("="*70)
    
    return episode_rewards, timestep_rewards


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='MBPO for Pendulum')
    
    # Environment
    parser.add_argument('--seed', type=int, default=0, help='Random seed')
    parser.add_argument('--num-episodes', type=int, default=15, help='Number of episodes')
    parser.add_argument('--max-steps', type=int, default=200, help='Max steps per episode')
    parser.add_argument('--output-dir', type=str, default='seeds_data', help='Output directory')
    
    # Dynamics model
    parser.add_argument('--sigma', type=float, default=10.0, help='BLR prior variance')
    parser.add_argument('--sigma_n', type=float, default=1e-3, help='BLR noise variance')
    parser.add_argument('--training-iter-dx', type=int, default=100, help='Dynamics training iterations')
    parser.add_argument('--hidden-dim-dx', type=int, default=200, help='Dynamics hidden dim')
    parser.add_argument('--predict_with_bias', type=bool, default=True, help='Use bias in BLR')
    
    # Policy
    parser.add_argument('--policy-hidden-dim', type=int, default=256, help='Policy network hidden dim')
    parser.add_argument('--policy-lr', type=float, default=3e-4, help='Policy learning rate')
    parser.add_argument('--gamma', type=float, default=0.99, help='Discount factor')
    
    # MBPO specific
    parser.add_argument('--num-model-rollouts', type=int, default=400, help='Synthetic rollouts per episode')
    parser.add_argument('--rollout-length', type=int, default=5, help='Length of each rollout')
    parser.add_argument('--policy-updates-per-episode', type=int, default=40, help='Policy updates per episode')
    
    args = parser.parse_args()
    
    run_mbpo_pendulum(args)
