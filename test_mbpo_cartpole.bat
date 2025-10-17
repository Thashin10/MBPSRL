@echo off
REM Quick test of MBPO CartPole with optimizations
echo ========================================
echo Quick Test: MBPO CartPole (2 episodes)
echo ========================================
echo.

REM Activate conda environment (Miniconda3 location)
call C:\Users\thash\Miniconda3\Scripts\activate.bat mbpsrl
if errorlevel 1 (
    echo ERROR: Failed to activate conda environment
    pause
    exit /b 1
)

echo Conda environment activated: mbpsrl
echo.

REM Create output directory
if not exist test_output mkdir test_output

REM Run test
echo Running MBPO CartPole test...
echo.
python baselines\mbpo\run_mbpo_cartpole.py --seed 0 --num-episodes 2 --output-dir test_output

echo.
echo ========================================
echo Test complete!
echo ========================================
echo.

REM Check if files were created
if exist test_output\mbpo_cartpole_log_seed0.txt (
    echo [OK] mbpo_cartpole_log_seed0.txt created
) else (
    echo [MISSING] mbpo_cartpole_log_seed0.txt
)

if exist test_output\mbpo_cartpole_timestep_rewards_seed0.txt (
    echo [OK] mbpo_cartpole_timestep_rewards_seed0.txt created
) else (
    echo [MISSING] mbpo_cartpole_timestep_rewards_seed0.txt
)

echo.
pause
