# Quick status check - run this anytime to see current progress
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "EXPERIMENT STATUS - $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$experiments = @{
    "CartPole WITH oracle" = "cartpole_timestep_rewards_with_oracle.txt"
    "CartPole WITHOUT oracle" = "cartpole_timestep_rewards_without_oracle.txt"
    "Pendulum WITH oracle" = "pendulum_timestep_rewards_with_oracle.txt"
    "Pendulum WITHOUT oracle" = "pendulum_timestep_rewards_without_oracle.txt"
}

foreach ($name in $experiments.Keys) {
    $file = $experiments[$name]
    Write-Host "`n$name" -ForegroundColor Yellow
    
    if (Test-Path $file) {
        $lines = @(Get-Content $file)
        if ($lines.Count -gt 0) {
            $last = $lines[-1] -split '\s+'
            $ts = [int]$last[0]
            $rew = [math]::Round([double]$last[1], 1)
            $ep = [math]::Floor($ts / 200)
            $pct = [math]::Round(($ts / 3000) * 100, 1)
            
            if ($ts -ge 3000) {
                Write-Host "  ✓ COMPLETE!" -ForegroundColor Green
            } else {
                Write-Host "  ✓ RUNNING" -ForegroundColor Green
            }
            Write-Host "  Episode: $ep/15 | Timestep: $ts/3000 ($pct%)" -ForegroundColor White
            Write-Host "  Cumulative Reward: $rew" -ForegroundColor White
        }
    } else {
        Write-Host "  ⏳ Not started or in episode 0 training" -ForegroundColor Gray
    }
}

Write-Host "`n========================================`n" -ForegroundColor Cyan
