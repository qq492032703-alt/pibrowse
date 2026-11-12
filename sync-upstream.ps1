<#
.SYNOPSIS
  Trigger an immediate mirror sync of aronhy/pibrowse -> your GitHub repo.
.DESCRIPTION
  The real syncing runs in GitHub Actions (.github/workflows/upstream-sync.yml),
  so this machine does NOT need to be on. This script just fires that workflow
  on demand, or installs a Windows Scheduled Task to fire it periodically.
.EXAMPLES
  pwsh -File sync-upstream.ps1                 # sync now
  pwsh -File sync-upstream.ps1 -InstallTask    # install daily 09:00 task
  pwsh -File sync-upstream.ps1 -RemoveTask     # remove the task
#>
param(
  [switch]$InstallTask,
  [switch]$RemoveTask,
  [string]$TaskTime = "09:00",
  [string]$Repo = "qq492032703-alt/pibrowse",
  [string]$Workflow = "upstream-sync.yml"
)

$ErrorActionPreference = "Stop"
$TaskName = "PiBrowse-Upstream-Sync"

if ($RemoveTask) {
  schtasks /Delete /TN $TaskName /F 2>$null
  Write-Host "Removed scheduled task '$TaskName'."
  return
}

if ($InstallTask) {
  $self = $MyInvocation.MyCommand.Path
  $pwsh = (Get-Command pwsh).Source
  $action = "`"$pwsh`" -NoProfile -File `"$self`""
  schtasks /Create /TN $TaskName /SC DAILY /ST $TaskTime /TR $action /F | Out-Null
  Write-Host "Installed daily task '$TaskName' at $TaskTime."
  return
}

# default: trigger the workflow now
Write-Host "Triggering '$Workflow' on $Repo ..."
gh workflow run $Workflow --repo $Repo
Start-Sleep -Seconds 4
gh run list --repo $Repo --workflow $Workflow --limit 3
Write-Host "Done. Watch it at: https://github.com/$Repo/actions"
