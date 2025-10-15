# Monitor experiment progress
$files = @(
    "cartpole_timestep_rewards_with_oracle.txt",
    "cartpole_timestep_rewards_without_oracle.txt",
    "pendulum_timestep_rewards_with_oracle.txt",
    "pendulum_timestep_rewards_without_oracle.txt"
)

Write-Host "Monitoring experiment progress..." -ForegroundColor Cyan
Write-Host "Press Ctrl+C to stop monitoring" -ForegroundColor Gray
Write-Host ""

while ($true) {
    Clear-Host
    Write-Host "=" * 70 -ForegroundColor Cyan
    Write-Host "EXPERIMENT PROGRESS MONITOR" -ForegroundColor Cyan  
    Write-Host "=" * 70 -ForegroundColor Cyan
    Write-Host ""
    
    $anyRunning = $false
    
    foreach ($file in $files) {
        $expName = $file -replace '_timestep_rewards_', ' ' -replace '\.txt', '' -replace '_', ' '
        
        if (Test-Path $file) {
            $lines = Get-Content $file
            $lastLine = $lines[-1] -split '\s+'
            $timestep = [int]$lastLine[0]
            $cumReward = [math]::Round([double]$lastLine[1], 2)
            $episode = [math]::Floor($timestep / 200)
            $progress = [math]::Round(($timestep / 3000) * 100, 1)
            
            Write-Host "✓ $expName" -ForegroundColor Green
            Write-Host "  Episode: $episode/15 | Timestep: $timestep/3000 ($progress%)" -ForegroundColor White
            Write-Host "  Cumulative Reward: $cumReward" -ForegroundColor White
            
            if ($timestep -lt 3000) {
                $anyRunning = $true
            }
        } else {
            Write-Host "⏳ $expName" -ForegroundColor Yellow
            Write-Host "  Waiting to start or in early training..." -ForegroundColor Gray
            $anyRunning = $true
        }
        Write-Host ""
    }
    
    if (-not $anyRunning) {
        Write-Host "=" * 70 -ForegroundColor Green
        Write-Host "ALL EXPERIMENTS COMPLETE!" -ForegroundColor Green
        Write-Host "=" * 70 -ForegroundColor Green
        break
    }
    
    Write-Host "Last updated: $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Gray
    Start-Sleep -Seconds 5
}
