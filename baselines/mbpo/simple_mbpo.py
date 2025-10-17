"""
Simplified Model-Based Policy Optimization (MBPO)

This is a lightweight MBPO implementation that:
1. Learns a dynamics model (using existing BNN)
2. Trains a simple policy network using model rollouts
3. Uses both real and synthetic data for training

Simplified from full MBPO by using a basic policy gradient instead of full SAC.
"""

import numpy as np
import torch
import torch.nn as nn
import torch.optim as optim
from collections import deque
import random


class SimpleActor(nn.Module):
    """Simple policy network (actor) for continuous actions"""
    
    def __init__(self, state_dim, action_dim, hidden_dim=256, action_low=-1.0, action_high=1.0):
        super(SimpleActor, self).__init__()
        self.action_low = torch.FloatTensor(action_low if isinstance(action_low, np.ndarray) else [action_low])
        self.action_high = torch.FloatTensor(action_high if isinstance(action_high, np.ndarray) else [action_high])
        
        self.net = nn.Sequential(
            nn.Linear(state_dim, hidden_dim),
            nn.ReLU(),
            nn.Linear(hidden_dim, hidden_dim),
            nn.ReLU(),
            nn.Linear(hidden_dim, action_dim),
            nn.Tanh()  # Output in [-1, 1], then scale
        )
        
        # Better initialization for smoother policy
        self._init_weights()
    
    def _init_weights(self):
        """Initialize network weights with smaller values for smoother policy"""
        for layer in self.net:
            if isinstance(layer, nn.Linear):
                nn.init.xavier_uniform_(layer.weight, gain=0.5)
                nn.init.constant_(layer.bias, 0)
    
    def forward(self, state):
        """Forward pass through network"""
        action = self.net(state)
        # Scale from [-1, 1] to [action_low, action_high]
        action = self.action_low + (action + 1.0) * 0.5 * (self.action_high - self.action_low)
        return action
    
    def get_action(self, state, deterministic=False, noise_scale=0.1):
        """Get action from policy with optional exploration noise"""
        with torch.no_grad():
            if not isinstance(state, torch.Tensor):
                state = torch.FloatTensor(state).unsqueeze(0)
            action = self.forward(state)
            
            if not deterministic:
                # Add exploration noise
                noise = torch.randn_like(action) * noise_scale
                action = action + noise
                # Clip to bounds
                action = torch.max(torch.min(action, self.action_high), self.action_low)
            
            return action.squeeze(0).numpy()


class SimpleCritic(nn.Module):
    """Simple value network (critic) for Q-value estimation"""
    
    def __init__(self, state_dim, action_dim, hidden_dim=256):
        super(SimpleCritic, self).__init__()
        
        self.net = nn.Sequential(
            nn.Linear(state_dim + action_dim, hidden_dim),
            nn.ReLU(),
            nn.Linear(hidden_dim, hidden_dim),
            nn.ReLU(),
            nn.Linear(hidden_dim, 1)
        )
    
    def forward(self, state, action):
        """Forward pass through network"""
        x = torch.cat([state, action], dim=-1)
        return self.net(x)


class ReplayBuffer:
    """Experience replay buffer for storing transitions"""
    
    def __init__(self, capacity=100000):
        self.buffer = deque(maxlen=capacity)
    
    def push(self, state, action, reward, next_state, done):
        """Add transition to buffer"""
        self.buffer.append((state, action, reward, next_state, done))
    
    def sample(self, batch_size):
        """Sample random batch from buffer"""
        batch = random.sample(self.buffer, batch_size)
        states, actions, rewards, next_states, dones = zip(*batch)
        
        return (
            np.array(states),
            np.array(actions),
            np.array(rewards).reshape(-1, 1),
            np.array(next_states),
            np.array(dones).reshape(-1, 1)
        )
    
    def __len__(self):
        return len(self.buffer)


class SimplifiedMBPO:
    """
    Simplified Model-Based Policy Optimization
    
    Combines learned dynamics model with policy learning using synthetic rollouts.
    """
    
    def __init__(self, state_dim, action_dim, action_low, action_high, 
                 dynamics_model, hidden_dim=256, lr=3e-4, gamma=0.99, env_name='cartpole'):
        """
        Args:
            state_dim: Dimension of state space
            action_dim: Dimension of action space
            action_low: Lower bound of action space
            action_high: Upper bound of action space
            dynamics_model: Learned dynamics model (NB_dx_tf)
            hidden_dim: Hidden layer size for networks
            lr: Learning rate
            gamma: Discount factor
            env_name: Environment name for oracle reward function
        """
        self.state_dim = state_dim
        self.action_dim = action_dim
        self.gamma = gamma
        self.dynamics_model = dynamics_model
        self.env_name = env_name.lower()
        
        # Create actor and critic networks
        self.actor = SimpleActor(state_dim, action_dim, hidden_dim, action_low, action_high)
        self.critic = SimpleCritic(state_dim, action_dim, hidden_dim)
        
        # Optimizers
        self.actor_optimizer = optim.Adam(self.actor.parameters(), lr=lr)
        self.critic_optimizer = optim.Adam(self.critic.parameters(), lr=lr)
        
        # Replay buffers (separate for real and model data)
        self.real_buffer = ReplayBuffer(capacity=50000)
        self.model_buffer = ReplayBuffer(capacity=50000)
        
        # Training parameters
        self.batch_size = 256
        self.noise_scale = 0.1
        
    def select_action(self, state, deterministic=False):
        """Select action from policy"""
        return self.actor.get_action(state, deterministic, self.noise_scale)
    
    def add_real_transition(self, state, action, reward, next_state, done):
        """Add transition from real environment to buffer"""
        self.real_buffer.push(state, action, reward, next_state, done)
    
    def generate_model_rollouts(self, num_rollouts=1000, rollout_length=5):
        """
        Generate synthetic rollouts using learned dynamics model
        
        Args:
            num_rollouts: Number of rollout trajectories to generate
            rollout_length: Length of each rollout
        """
        if len(self.real_buffer) < self.batch_size:
            return  # Need enough real data first
        
        # Sample starting states from real buffer
        states, _, _, _, _ = self.real_buffer.sample(min(num_rollouts, len(self.real_buffer)))
        
        for state in states:
            current_state = state.copy()
            
            for _ in range(rollout_length):
                # Get action from policy
                action = self.select_action(current_state, deterministic=False)
                
                # Predict next state using dynamics model
                state_tensor = torch.cat([
                    torch.FloatTensor(current_state),
                    torch.FloatTensor(action)
                ]).double()
                
                # Get prediction (delta)
                delta = self.dynamics_model.predict(state_tensor.numpy().reshape(1, -1))
                next_state = current_state + delta.flatten()
                
                # Estimate reward (simple heuristic or use learned reward model)
                reward = self._estimate_reward(current_state, action, next_state)
                
                # Add to model buffer
                self.model_buffer.push(current_state, action, reward, next_state, False)
                
                current_state = next_state
    
    def _estimate_reward(self, state, action, next_state):
        """
        Estimate reward using oracle functions
        This significantly improves performance by using true reward structure
        """
        if 'cartpole' in self.env_name:
            # CartPole oracle reward
            x = next_state[0]
            x_dot = next_state[1] if len(next_state) > 1 else 0
            theta = np.arctan2(next_state[3], next_state[2]) if len(next_state) > 3 else 0
            theta_dot = next_state[4] if len(next_state) > 4 else 0
            
            reward = np.cos(theta) - 0.01 * x**2
            # Add shaping for stability
            reward += 0.1 * np.exp(-abs(theta)) if abs(theta) < 0.2 else 0
            
        elif 'pendulum' in self.env_name:
            # Pendulum oracle reward
            cos_theta = next_state[0] if len(next_state) > 0 else 0
            sin_theta = next_state[1] if len(next_state) > 1 else 0
            theta_dot = next_state[2] if len(next_state) > 2 else 0
            
            theta = np.arctan2(sin_theta, cos_theta)
            reward = -(theta**2 + 0.1 * theta_dot**2 + 0.001 * action**2)
            
        else:
            # Fallback to simple negative cost
            reward = -0.1
        
        return reward
    
    def train_policy(self, num_updates=10):
        """Train actor and critic using data from both buffers"""
        if len(self.real_buffer) < self.batch_size:
            return
        
        for _ in range(num_updates):
            # Sample from both real and model buffers
            real_ratio = 0.5  # Mix 50% real, 50% model data
            real_batch_size = int(self.batch_size * real_ratio)
            model_batch_size = self.batch_size - real_batch_size
            
            # Get real data
            if len(self.real_buffer) >= real_batch_size:
                real_states, real_actions, real_rewards, real_next_states, real_dones = \
                    self.real_buffer.sample(real_batch_size)
            else:
                real_states, real_actions, real_rewards, real_next_states, real_dones = \
                    self.real_buffer.sample(len(self.real_buffer))
            
            # Get model data if available
            if len(self.model_buffer) >= model_batch_size:
                model_states, model_actions, model_rewards, model_next_states, model_dones = \
                    self.model_buffer.sample(model_batch_size)
                
                # Combine batches
                states = np.vstack([real_states, model_states])
                actions = np.vstack([real_actions, model_actions])
                rewards = np.vstack([real_rewards, model_rewards])
                next_states = np.vstack([real_next_states, model_next_states])
                dones = np.vstack([real_dones, model_dones])
            else:
                states = real_states
                actions = real_actions
                rewards = real_rewards
                next_states = real_next_states
                dones = real_dones
            
            # Convert to tensors
            states = torch.FloatTensor(states)
            actions = torch.FloatTensor(actions)
            rewards = torch.FloatTensor(rewards)
            next_states = torch.FloatTensor(next_states)
            dones = torch.FloatTensor(dones)
            
            # Update critic
            with torch.no_grad():
                next_actions = self.actor(next_states)
                target_q = rewards + (1 - dones) * self.gamma * self.critic(next_states, next_actions)
            
            current_q = self.critic(states, actions)
            critic_loss = nn.MSELoss()(current_q, target_q)
            
            self.critic_optimizer.zero_grad()
            critic_loss.backward()
            self.critic_optimizer.step()
            
            # Update actor
            new_actions = self.actor(states)
            actor_loss = -self.critic(states, new_actions).mean()
            
            self.actor_optimizer.zero_grad()
            actor_loss.backward()
            self.actor_optimizer.step()
    
    def decrease_noise(self, factor=0.95):
        """Decay exploration noise over time"""
        self.noise_scale = max(0.01, self.noise_scale * factor)
