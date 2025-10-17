@echo off
REM MBPO Pendulum - All 5 seeds (approximately 1.5-2 hours)
echo ========================================
echo MBPO Pendulum - 5 Seeds
echo ========================================
echo.

call C:\Users\thash\Miniconda3\Scripts\activate.bat mbpsrl
if errorlevel 1 (
    echo ERROR: Failed to activate conda environment
    pause
    exit /b 1
)

REM Use provided output directory or create new one
if "%1"=="" (
    set timestamp=%date:~10,4%%date:~4,2%%date:~7,2%_%time:~0,2%%time:~3,2%%time:~6,2%
    set timestamp=!timestamp: =0!
    set output_dir=optimized_results_!timestamp!
    mkdir !output_dir! 2>nul
) else (
    set output_dir=%1
)

echo Output directory: %output_dir%
echo.
echo Starting 5 seeds (approximately 1.5-2 hours total)...
echo.

for /l %%s in (0,1,4) do (
    echo ========================================
    echo Running MBPO Pendulum - Seed %%s / 4
    echo ========================================
    echo Start time: %time%
    echo.
    
    python baselines\mbpo\run_mbpo_pendulum.py --seed %%s --num-episodes 15 --output-dir %output_dir%
    
    echo.
    echo Seed %%s completed at %time%
    echo.
)

echo.
echo ========================================
echo MBPO Pendulum Complete!
echo ========================================
echo All 5 seeds finished
echo Output directory: %output_dir%
echo.
pause
