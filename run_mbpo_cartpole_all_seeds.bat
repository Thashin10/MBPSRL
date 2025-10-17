@echo off
REM MBPO CartPole - All 5 seeds (approximately 1.5-2 hours)
echo ========================================
echo MBPO CartPole - 5 Seeds
echo ========================================
echo.

call C:\Users\thash\Miniconda3\Scripts\activate.bat mbpsrl
if errorlevel 1 (
    echo ERROR: Failed to activate conda environment
    pause
    exit /b 1
)

REM Create output directory with timestamp
set timestamp=%date:~10,4%%date:~4,2%%date:~7,2%_%time:~0,2%%time:~3,2%%time:~6,2%
set timestamp=%timestamp: =0%
set output_dir=optimized_results_%timestamp%
mkdir %output_dir% 2>nul

echo Output directory: %output_dir%
echo.
echo Starting 5 seeds (approximately 1.5-2 hours total)...
echo.

for /l %%s in (0,1,4) do (
    echo ========================================
    echo Running MBPO CartPole - Seed %%s / 4
    echo ========================================
    echo Start time: %time%
    echo.
    
    python baselines\mbpo\run_mbpo_cartpole.py --seed %%s --num-episodes 15 --output-dir %output_dir%
    
    echo.
    echo Seed %%s completed at %time%
    echo.
)

echo.
echo ========================================
echo MBPO CartPole Complete!
echo ========================================
echo All 5 seeds finished
echo Output directory: %output_dir%
echo.
pause
