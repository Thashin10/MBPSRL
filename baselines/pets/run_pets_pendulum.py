"""
PETS (Probabilistic Ensembles with Trajectory Sampling) for Pendulum

Based on: Chua et al. (2018) "Deep Reinforcement Learning in a Handful of Trials 
using Probabilistic Dynamics Models"

This is adapted for the Pendulum environment with appropriate hyperparameters.
"""

import numpy as np
import sys
import os
import argparse
import torch

# Add parent directory to path
sys.path.append(os.path.dirname(os.path.dirname(os.path.dirname(__file__))))

from pendulum_gym import PendulumEnv
from tf_models.constructor import construct_shallow_model
from tf_models.fake_env import FakeEnv
import scipy.stats as stats

os.environ["CUDA_VISIBLE_DEVICES"] = "0"


class PETS_CEM:
    """CEM with Trajectory Sampling for PETS"""
    
    def __init__(self, env, fake_env, args):
        self.env = env
        self.fake_env = fake_env
        self.args = args
        
        self.ub = env.action_space.high[0]
        self.lb = env.action_space.low[0]
        self.action_shape = len(env.action_space.sample())
        self.plan_hor = args.plan_hor
        self.soln_dim = self.action_shape * self.plan_hor
        
        self.num_trajs = args.num_trajs
        self.num_elites = args.num_elites
        self.max_iters = args.max_iters
        self.alpha = args.alpha
        self.epsilon = args.epsilon
        
        self.pre_means = np.zeros(self.soln_dim)
    
    def hori_planning(self, cur_s):
        """Plan action sequence using CEM with Trajectory Sampling"""
        cur_s = cur_s.squeeze()
        
        # Initialize distribution
        init_means = np.concatenate((self.pre_means[self.action_shape:].flatten(), np.zeros(self.action_shape).flatten()))
        init_vars = self.args.var * np.ones(self.soln_dim)
        means = init_means
        vars = init_vars
        
        # CEM iterations
        for i in range(self.max_iters):
            # Sample action sequences
            X = stats.truncnorm(-2, 2, loc=np.zeros_like(means), scale=np.ones_like(means))
            lb_dist, ub_dist = means - self.lb, self.ub - means
            constrained_var = np.minimum(np.minimum(np.square(lb_dist / 2), np.square(ub_dist / 2)), vars)
            samples = X.rvs(size=[self.num_trajs, self.soln_dim]) * np.sqrt(constrained_var) + means
            
            # Evaluate trajectories using Trajectory Sampling
            rewards = []
            for action_seq in samples:
                traj_reward = self.evaluate_trajectory_ts(cur_s, action_seq)
                rewards.append(traj_reward)
            
            rewards = np.array(rewards)
            
            # Select elites
            elite_idxs = rewards.argsort()[-self.num_elites:]
            elite_samples = samples[elite_idxs]
            
            # Update distribution
            new_means = elite_samples.mean(axis=0)
            new_vars = elite_samples.var(axis=0)
            
            means = self.alpha * means + (1 - self.alpha) * new_means
            vars = self.alpha * vars + (1 - self.alpha) * new_vars
            
            # Check convergence
            if np.max(np.abs(new_means - means)) < self.epsilon:
                break
        
        # Store for warm-starting next step
        self.pre_means = means
        
        # Return first action
        return means[:self.action_shape]
    
    def evaluate_trajectory_ts(self, init_state, action_seq):
        """Evaluate trajectory using Trajectory Sampling"""
        state = init_state.copy()
        total_reward = 0.0
        
        for t in range(self.plan_hor):
            action = action_seq[t * self.action_shape:(t + 1) * self.action_shape]
            
            # Step using fake environment with TS
            next_state, reward, done, _ = self.fake_env.step(state, action, deterministic=False)
            
            total_reward += reward
            state = next_state
            
            if done:
                break
        
        return total_reward


def run_pets_pendulum(args):
    """Main PETS training loop for Pendulum"""
    
    # Set random seeds
    np.random.seed(args.seed)
    torch.manual_seed(args.seed)
    import random
    random.seed(args.seed)
    
    print("=" * 60)
    print("PETS - Pendulum")
    print("=" * 60)
    print("Seed:", args.seed)
    print("Episodes:", args.num_episodes)
    print("Ensemble size:", args.num_networks)
    print("CEM trajectories:", args.num_trajs)
    print("=" * 60)
    
    # Initialize environment
    env = PendulumEnv()
    obs_shape = env.observation_space.shape[0]
    action_shape = len(env.action_space.sample())
    
    # Add termination function for Pendulum
    # Pendulum is a continuous task - no early termination
    def pendulum_termination_fn(obs, act, next_obs):
        """
        Pendulum has no termination condition - episodes run for fixed duration.
        Returns array of zeros indicating never done.
        """
        if len(next_obs.shape) == 1:
            return np.array([[0.0]], dtype=np.float32)
        else:
            batch_size = next_obs.shape[0]
            return np.zeros((batch_size, 1), dtype=np.float32)
    
    env.termination_fn = pendulum_termination_fn
    
    # Add oracle reward function for Pendulum
    # Pendulum reward: -(theta^2 + 0.1*theta_dot^2 + 0.001*action^2)
    def pendulum_reward_fn(obs, act, next_obs):
        """
        Pendulum reward based on angle and angular velocity.
        obs, act, next_obs are arrays of shape [batch_size, dim]
        next_obs: [cos(theta), sin(theta), theta_dot]
        Returns array of shape [batch_size, 1]
        """
        if len(next_obs.shape) == 1:
            next_obs = next_obs[None]
            act = act[None] if len(act.shape) == 1 else act
            return_single = True
        else:
            return_single = False
        
        cos_th = next_obs[:, 0]
        sin_th = next_obs[:, 1]
        thdot = next_obs[:, 2]
        
        # Compute angle from cos and sin
        th = np.arctan2(sin_th, cos_th)
        
        # Pendulum reward: -(theta^2 + 0.1*theta_dot^2 + 0.001*action^2)
        reward = -(th**2 + 0.1 * thdot**2 + 0.001 * (act.squeeze()**2))
        reward = reward[:, None]  # Shape [batch_size, 1]
        
        if return_single:
            return reward[0:1]
        return reward
    
    # Initialize dynamics model ensemble
    dx_model = construct_shallow_model(
        obs_dim=obs_shape,
        act_dim=action_shape,
        hidden_dim=args.hidden_dim_dx,
        num_networks=args.num_networks,
        num_elites=args.num_elites
    )
    
    # Data storage
    dataset_states = []
    dataset_actions = []
    dataset_next_states = []
    
    cum_rewards = []
    cumulative_rewards_over_time = []
    total_timesteps = 0
    total_cumulative_reward = 0.0
    
    # Training loop
    for episode in range(args.num_episodes):
        print("\n" + "=" * 60)
        print("Episode {}/{}".format(episode + 1, args.num_episodes))
        print("=" * 60)
        
        # Reset environment
        state = torch.tensor(env.reset(), dtype=torch.float32).squeeze()
        done = False
        cum_reward = 0.0
        episode_steps = 0
        
        # Create fake environment (after first episode)
        if episode > 0:
            print("Training dynamics ensemble...")
            states_array = np.array(dataset_states)
            actions_array = np.array(dataset_actions).reshape(-1, 1)  # Ensure shape (N, 1)
            train_in = np.concatenate([states_array, actions_array], axis=-1)
            train_out = np.array(dataset_next_states) - states_array  # Predict deltas
            
            dx_model.train(train_in, train_out, epochs=args.training_iter_dx, hide_progress=True)
            print("Ensemble training complete")
            
            # Create fake environment for planning with oracle rewards
            fake_env = FakeEnv(dx_model, env, reward_fn=pendulum_reward_fn)
            cem = PETS_CEM(env, fake_env, args)
        
        # Episode rollout
        while not done and episode_steps < 200:
            if episode == 0:
                # Random actions for first episode
                u = env.action_space.sample()[0]  # Extract scalar from array
            else:
                # Plan using CEM with TS
                action_array = cem.hori_planning(state.numpy())
                u = float(np.ravel(action_array)[0])  # Flatten and extract first element
            
            # Execute action
            new_state, r, done, _ = env.step(u)
            new_state = torch.tensor(new_state, dtype=torch.float32).squeeze()
            r = torch.tensor([r], dtype=torch.float32)
            
            # Store transition
            dataset_states.append(state.numpy())
            dataset_actions.append(np.array([u]))  # Store as array for consistency
            dataset_next_states.append(new_state.numpy())
            
            # Update cumulative reward
            cum_reward += r.item()
            total_timesteps += 1
            total_cumulative_reward += r.item()
            cumulative_rewards_over_time.append([total_timesteps, total_cumulative_reward])
            
            state = new_state
            episode_steps += 1
        
        print("Episode {}: reward = {:.2f}, steps = {}, total_timesteps = {}".format(
            episode, cum_reward, episode_steps, total_timesteps))
        cum_rewards.append([episode, cum_reward])
    
    # Save results
    seed_suffix = '_seed' + str(args.seed)
    output_dir = args.output_dir
    os.makedirs(output_dir, exist_ok=True)
    
    np.savetxt(
        os.path.join(output_dir, 'pets_pendulum_log' + seed_suffix + '.txt'),
        cum_rewards
    )
    np.savetxt(
        os.path.join(output_dir, 'pets_pendulum_timestep_rewards' + seed_suffix + '.txt'),
        cumulative_rewards_over_time
    )
    
    print("\n" + "=" * 60)
    print("PETS COMPLETE")
    print("=" * 60)
    print("Total timesteps: {}, Final cumulative reward: {:.2f}".format(
        total_timesteps, total_cumulative_reward
    ))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='PETS for Pendulum')
    
    # Environment
    parser.add_argument('--num-episodes', type=int, default=15, help='Number of episodes')
    parser.add_argument('--seed', type=int, default=0, help='Random seed')
    parser.add_argument('--output-dir', type=str, default='seeds_data', help='Output directory')
    
    # Model ensemble (Pendulum-specific hyperparameters)
    parser.add_argument('--num-networks', type=int, default=5, help='Ensemble size')
    parser.add_argument('--num-elites-model', type=int, default=5, help='Elite networks')
    parser.add_argument('--hidden-dim-dx', type=int, default=200, help='Hidden dimension')
    parser.add_argument('--training-iter-dx', type=int, default=100, help='Training iterations')
    
    # CEM parameters (Pendulum-specific)
    parser.add_argument('--num-trajs', type=int, default=100, help='CEM trajectories')
    parser.add_argument('--num-elites', type=int, default=5, help='CEM elites')
    parser.add_argument('--alpha', type=float, default=0.0, help='CEM smoothing')
    parser.add_argument('--plan-hor', type=int, default=30, help='Planning horizon')
    parser.add_argument('--max-iters', type=int, default=5, help='CEM iterations')
    parser.add_argument('--epsilon', type=float, default=0.001, help='CEM convergence')
    parser.add_argument('--var', type=float, default=3.0, help='Initial variance')
    
    args = parser.parse_args()
    
    run_pets_pendulum(args)
