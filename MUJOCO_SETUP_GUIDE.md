# Setting up MuJoCo for Reacher and Pusher Environments

## Current Status
- Python 3.7.1 ✓
- TensorFlow 1.14 ✓
- Gym 0.9.4 ✓
- **MuJoCo and mujoco-py** ❌ NOT INSTALLED

## What is MuJoCo?
MuJoCo (Multi-Joint dynamics with Contact) is a physics engine for robotics simulation. The Reacher and Pusher tasks require it.

## Installation Steps

### Option 1: Install MuJoCo 150 (Recommended for Python 3.7 + mujoco-py 0.5.7)

**Step 1: Download MuJoCo 150**
1. Visit: https://www.roboti.us/download.html
2. Download `mjpro150_win64.zip` (for Windows)
3. OR use the newer free MuJoCo from: https://github.com/deepmind/mujoco/releases

**Step 2: Extract MuJoCo**
```powershell
# Create MuJoCo directory
mkdir C:\Users\thash\.mujoco
# Extract mjpro150 folder to C:\Users\thash\.mujoco\mjpro150
```

**Step 3: Get MuJoCo License (if using old version)**
- For mjpro150: Need a license key (mjkey.txt)
- For newer free MuJoCo 210+: No license needed!

**Step 4: Set Environment Variables**
```powershell
# Add to system PATH (permanently):
# Control Panel → System → Advanced → Environment Variables
# Add to Path:
C:\Users\thash\.mujoco\mjpro150\bin

# Or set temporarily in PowerShell:
$env:PATH += ";C:\Users\thash\.mujoco\mjpro150\bin"
```

**Step 5: Install mujoco-py**
```powershell
# Activate environment
C:\Users\thash\Miniconda3\Scripts\conda.exe activate mbpsrl

# Install mujoco-py (version 0.5.7 for compatibility with repo)
pip install mujoco-py==0.5.7

# OR if that fails, try:
pip install mujoco-py
```

**Step 6: Install Visual C++ Build Tools (if compilation fails)**
- Download: https://visualstudio.microsoft.com/visual-cpp-build-tools/
- Install "Desktop development with C++" workload

### Option 2: Use Newer Free MuJoCo 210+ (Easier)

**Step 1: Install new MuJoCo**
```powershell
pip install mujoco
```

**Step 2: Update code to use new MuJoCo API**
This requires modifying `reacher.py` and `pusher.py` to use the new API.

### Option 3: Skip MuJoCo Tasks (Fastest)

If MuJoCo setup is complex, we can:
1. Focus on CartPole and Pendulum (already working ✓)
2. Document Reacher/Pusher as "future work"
3. The main PSRL contribution is already demonstrated

## Testing MuJoCo Installation

After installation, test with:
```powershell
C:\Users\thash\Miniconda3\Scripts\conda.exe run -n mbpsrl python -c "import mujoco_py; print('MuJoCo OK')"
```

## Troubleshooting

**Error: "No module named 'mujoco_py'"**
- Solution: Install mujoco-py (see Step 5 above)

**Error: "GLEW initialization error"**
- Solution: Install Visual C++ Redistributable
- Download: https://support.microsoft.com/en-us/help/2977003/the-latest-supported-visual-c-downloads

**Error: "Could not find mjpro150 directory"**
- Solution: Check that MuJoCo is in `C:\Users\thash\.mujoco\mjpro150`
- Set MUJOCO_PY_MJPRO_PATH environment variable

**Error: "Missing library"**
- Solution: Add MuJoCo bin directory to PATH (see Step 4)

## Repository Specifications

According to the paper specifications:
- **MuJoCo version**: Not explicitly specified, but mujoco-py 0.5.7 suggests MuJoCo 150
- **Python**: 3.5+ (we have 3.7.1 ✓)
- **TensorFlow**: 1.14 (we have this ✓)
- **Gym**: 0.9.4 (we have this ✓)

## Recommendation

Given the time investment for MuJoCo setup:

**Option A: Quick path (Recommended)**
- You already have excellent results for CartPole and Pendulum
- These demonstrate the PSRL approach effectively
- Skip Reacher/Pusher for now
- Focus on:
  1. Finalizing plots and comparisons
  2. Writing up results
  3. Can add Reacher later if needed

**Option B: Install MuJoCo (2-3 hours setup time)**
- Follow Option 1 or 2 above
- Will enable Reacher and Pusher
- More complete replication
- Risk: May encounter Windows-specific compilation issues

**Option C: Use Docker/Linux VM**
- MuJoCo setup is easier on Linux
- Could use WSL2 or Docker
- Requires additional setup time

## Decision Point

Before proceeding with MuJoCo installation, consider:
1. **Time available**: MuJoCo setup can take 2-3 hours with troubleshooting
2. **Research value**: CartPole + Pendulum already show PSRL effectiveness
3. **Complexity**: Windows + MuJoCo + Python 3.7 can have compatibility issues

**What would you like to do?**
- A) Try MuJoCo installation now (~2-3 hours)
- B) Skip Reacher/Pusher, focus on polishing CartPole/Pendulum results
- C) Document current results first, add Reacher later if needed
