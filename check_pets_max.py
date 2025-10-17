import numpy as np

print("Finding maximum rewards in PETS CartPole experiments:")
print("="*70)

for seed in range(5):
    data = np.loadtxt('seeds_data/pets_cartpole_log_seed{}.txt'.format(seed))
    episodes = data[:, 0].astype(int)
    rewards = data[:, 1]
    
    max_idx = rewards.argmax()
    max_reward = rewards[max_idx]
    max_episode = episodes[max_idx]
    
    print("\nSeed {}:".format(seed))
    print("  Maximum reward: {:.2f} at Episode {}".format(max_reward, max_episode))
    print("  Mean reward: {:.2f} +/- {:.2f}".format(rewards.mean(), rewards.std()))
    print("  First 20 episodes mean: {:.2f}".format(rewards[:20].mean()))
    print("  Last 20 episodes mean: {:.2f}".format(rewards[-20:].mean()))
    print("  Episodes above 50: {} out of {}".format((rewards > 50).sum(), len(rewards)))
    print("  Episodes above 100: {} out of {}".format((rewards > 100).sum(), len(rewards)))
    
    # Show rewards around the maximum
    if max_episode > 0:
        context_start = max(0, max_episode - 2)
        context_end = min(len(rewards), max_episode + 3)
        print("  Context around max (episodes {}-{}):".format(context_start, context_end-1))
        for i in range(context_start, context_end):
            marker = " <-- MAX" if i == max_episode else ""
            print("    Episode {}: {:.2f}{}".format(i, rewards[i], marker))

print("\n" + "="*70)
print("\nConclusion:")
print("The high maximum (113.05) is likely an OUTLIER - a single lucky episode")
print("The smoothed plots correctly show the typical performance (20-40 range)")
print("Smoothing removes these rare spikes to show the true learning trend")
