"""
PETS (Probabilistic Ensembles with Trajectory Sampling) for CartPole

Based on: Chua et al. (2018) "Deep Reinforcement Learning in a Handful of Trials 
using Probabilistic Dynamics Models"

Key differences from MPC-PSRL:
1. Uses ensemble of neural networks (not Bayesian Linear Regression)
2. Trajectory Sampling: samples one model per trajectory rollout
3. No separate reward model - uses oracle rewards only
4. Retrains ensemble after each episode
"""

import numpy as np
import sys
import os
import argparse
import torch

# Add parent directory to path
sys.path.append(os.path.dirname(os.path.dirname(os.path.dirname(__file__))))

from cartpole_continuous import ContinuousCartPoleEnv
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
                # TRAJECTORY SAMPLING: Select one random model from ensemble for entire trajectory
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
        """
        Evaluate trajectory using Trajectory Sampling (TS).
        Randomly select one model from ensemble and use it for entire trajectory.
        """
        state = init_state.copy()
        total_reward = 0.0
        
        # Randomly select one model index to use for this trajectory
        # This is done internally by FakeEnv when deterministic=False
        
        for t in range(self.plan_hor):
            action = action_seq[t * self.action_shape:(t + 1) * self.action_shape]
            
            # Step using fake environment (with TS - random model selection)
            next_state, reward, done, _ = self.fake_env.step(state, action, deterministic=False)
            
            total_reward += reward
            state = next_state
            
            if done:
                break
        
        return total_reward


def run_pets_cartpole(args):
    """Main PETS training loop for CartPole"""
    
    # Set random seeds
    np.random.seed(args.seed)
    torch.manual_seed(args.seed)
    import random
    random.seed(args.seed)
    
    print("=" * 60)
    print("PETS - CartPole")
    print("=" * 60)
    print("Seed:", args.seed)
    print("Episodes:", args.num_episodes)
    print("Ensemble size:", args.num_networks)
    print("CEM trajectories:", args.num_trajs)
    print("=" * 60)
    
    # Initialize environment
    env = ContinuousCartPoleEnv()
    obs_shape = env.observation_space.shape[0]
    action_shape = len(env.action_space.sample())
    
    # Add termination function for CartPole
    # Episode terminates if pole angle > 12 degrees or cart position > 2.4
    def cartpole_termination_fn(obs, act, next_obs):
        """
        Determines if CartPole episode should terminate.
        obs, act, next_obs are arrays of shape [batch_size, dim]
        Returns array of shape [batch_size, 1] with 1.0 if done, 0.0 otherwise
        """
        if len(next_obs.shape) == 1:
            next_obs = next_obs[None]
            return_single = True
        else:
            return_single = False
        
        x = next_obs[:, 0]
        theta = next_obs[:, 2]
        
        # Done if cart goes outside bounds or pole tilts too much
        done = np.logical_or(
            np.abs(x) > 2.4,
            np.abs(theta) > 0.2095  # ~12 degrees in radians
        )
        
        done = done.astype(np.float32)[:, None]
        
        if return_single:
            return done[0]
        return done
    
    env.termination_fn = cartpole_termination_fn
    
    # Add oracle reward function for CartPole
    # In CartPole, reward is 1.0 for every step the pole stays upright
    def cartpole_reward_fn(obs, act, next_obs):
        """
        CartPole gives reward of 1.0 for each timestep the pole is balanced.
        obs, act, next_obs are arrays of shape [batch_size, dim]
        Returns array of shape [batch_size, 1]
        """
        if len(next_obs.shape) == 1:
            return np.array([[1.0]], dtype=np.float32)
        else:
            batch_size = next_obs.shape[0]
            return np.ones((batch_size, 1), dtype=np.float32)
    
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
        state = torch.tensor(env.reset(), dtype=torch.float32)
        done = False
        cum_reward = 0.0
        episode_steps = 0
        
        # Create fake environment (after first episode when we have data)
        if episode > 0:
            # Train ensemble on collected data
            print("Training dynamics ensemble...")
            states_array = np.array(dataset_states)
            actions_array = np.array(dataset_actions).reshape(-1, 1)  # Ensure shape (N, 1)
            train_in = np.concatenate([states_array, actions_array], axis=-1)
            train_out = np.array(dataset_next_states) - states_array  # Predict deltas
            
            dx_model.train(train_in, train_out, epochs=args.training_iter_dx, hide_progress=True)
            print("Ensemble training complete")
            
            # Create fake environment for planning with oracle rewards
            fake_env = FakeEnv(dx_model, env, reward_fn=cartpole_reward_fn)
            
            # Initialize CEM planner with fake environment
            cem = PETS_CEM(env, fake_env, args)
        
        # Episode rollout
        while not done and episode_steps < 200:  # Max 200 steps per episode
            if episode == 0:
                # Random actions for first episode (data collection)
                u = env.action_space.sample()[0]  # Extract scalar from array
            else:
                # Plan using CEM with Trajectory Sampling
                action_array = cem.hori_planning(state.numpy())
                u = float(np.ravel(action_array)[0])  # Flatten and extract first element
            
            # Execute action in real environment
            new_state, r, done, _ = env.step(u)
            new_state = torch.tensor(new_state, dtype=torch.float32)
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
        os.path.join(output_dir, 'pets_cartpole_log' + seed_suffix + '.txt'),
        cum_rewards
    )
    np.savetxt(
        os.path.join(output_dir, 'pets_cartpole_timestep_rewards' + seed_suffix + '.txt'),
        cumulative_rewards_over_time
    )
    
    print("\n" + "=" * 60)
    print("PETS COMPLETE")
    print("=" * 60)
    print("Total timesteps: {}, Final cumulative reward: {:.2f}".format(
        total_timesteps, total_cumulative_reward
    ))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='PETS for CartPole')
    
    # Environment
    parser.add_argument('--num-episodes', type=int, default=15, help='Number of episodes')
    parser.add_argument('--seed', type=int, default=0, help='Random seed')
    parser.add_argument('--output-dir', type=str, default='seeds_data', help='Output directory')
    
    # Model ensemble
    parser.add_argument('--num-networks', type=int, default=5, help='Ensemble size')
    parser.add_argument('--num-elites', type=int, default=5, help='Number of elite networks')
    parser.add_argument('--hidden-dim-dx', type=int, default=200, help='Hidden dimension')
    parser.add_argument('--training-iter-dx', type=int, default=100, help='Training iterations')
    
    # CEM parameters
    parser.add_argument('--num-trajs', type=int, default=500, help='CEM trajectories')
    parser.add_argument('--num-elites-cem', type=int, default=50, help='CEM elites')
    parser.add_argument('--alpha', type=float, default=0.1, help='CEM smoothing')
    parser.add_argument('--plan-hor', type=int, default=30, help='Planning horizon')
    parser.add_argument('--max-iters', type=int, default=5, help='CEM iterations')
    parser.add_argument('--epsilon', type=float, default=0.001, help='CEM convergence threshold')
    parser.add_argument('--var', type=float, default=1.0, help='Initial variance')
    
    args = parser.parse_args()
    
    # Fix naming conflict
    args.num_elites_cem_temp = args.num_elites_cem
    args.num_elites = args.num_elites  # For model ensemble
    args.num_elites = args.num_elites_cem  # For CEM
    
    run_pets_cartpole(args)
