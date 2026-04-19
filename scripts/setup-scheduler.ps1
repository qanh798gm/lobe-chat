# PowerShell script to register LobeChat backup in Windows Task Scheduler
# Run this script as Administrator once to set up automated backups

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$backupScript = Join-Path $scriptDir "backup.bat"

# Daily backup at 2:00 AM
$dailyAction = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c `"$backupScript`"" -WorkingDirectory $scriptDir
$dailyTrigger = New-ScheduledTaskTrigger -Daily -At "10:00PM"
$settings = New-ScheduledTaskSettingsSet -RunOnlyIfNetworkAvailable:$false -StartWhenAvailable
Register-ScheduledTask -TaskName "LobeChat Daily Backup" -Action $dailyAction -Trigger $dailyTrigger -Settings $settings -RunLevel Highest -Force

Write-Host "✅ LobeChat Daily Backup task registered (runs at 10:00 PM daily)"
Write-Host "   Backup script: $backupScript"
Write-Host ""
Write-Host "To run a manual backup now:"
Write-Host "   $backupScript"
Write-Host ""
Write-Host "To view/manage tasks: Task Scheduler > Task Scheduler Library > LobeChat Daily Backup"
