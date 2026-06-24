#Requires -Version 5.1
<#
.SYNOPSIS
  Toggle between multi-model and single-model mode.
.DESCRIPTION
  multi  — restore per-agent model assignments from profiles/multi-models.json
  single — all agents inherit the top-level model (optionally specify which model)
  status — show current mode and each agent's model
.EXAMPLE
  .\toggle-models.ps1 multi
  .\toggle-models.ps1 single
  .\toggle-models.ps1 single opencode-go/kimi-k2.7-code
  .\toggle-models.ps1 status
#>
[CmdletBinding()]
param(
  [Parameter(Position=0)]
  [ValidateSet('multi','single','status')]
  [string]$Action = 'status',

  [Parameter(Position=1)]
  [string]$ModelId
)

$ErrorActionPreference = 'Stop'
$ConfigDir = Join-Path $env:USERPROFILE '.config\opencode'
$ConfigFile = Join-Path $ConfigDir 'opencode.json'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProfilesDir = Join-Path $ConfigDir 'profiles'
$MultiProfile = Join-Path $ProfilesDir 'multi-models.json'

function Exit-WithPause($code = 0) {
  Write-Host ""
  Write-Host "  Press any key to close this window..." -ForegroundColor DarkGray
  try { $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown') } catch { Read-Host "  Press Enter to close" }
  exit $code
}

trap {
  Write-Host ""
  Write-Host "  UNEXPECTED ERROR: $($_.Exception.Message)" -ForegroundColor Red
  Exit-WithPause 1
}

if (-not (Test-Path -LiteralPath $ConfigFile)) {
  Write-Host "Config not found: $ConfigFile" -ForegroundColor Red
  Write-Host "Run install.ps1 first." -ForegroundColor Yellow
  Exit-WithPause 1
}

$raw = Get-Content -LiteralPath $ConfigFile -Raw
$raw = ($raw -split "`r?`n" | Where-Object { $_ -notmatch '^\s*//' }) -join "`r`n"
$cfg = $raw | ConvertFrom-Json

function Show-Status {
  Write-Host "`n=== Model Toggle Status ===" -ForegroundColor Cyan
  Write-Host "  Top-level model: $($cfg.model)" -ForegroundColor White
  Write-Host "  Small model:     $($cfg.small_model)" -ForegroundColor White
  Write-Host ""
  Write-Host "  Agent models:" -ForegroundColor White
  $agents = $cfg.agent.PSObject.Properties | Where-Object { $_.Name -notin @('title','summary','compaction') -and -not $_.Value.hidden }
  foreach ($a in $agents) {
    $m = $a.Value.model
    if ($m) {
      Write-Host "    $($a.Name): $m" -ForegroundColor Green
    } else {
      Write-Host "    $($a.Name): (inherits top-level: $($cfg.model))" -ForegroundColor Gray
    }
  }
  $hidden = $cfg.agent.PSObject.Properties | Where-Object { $_.Value.hidden -or $_.Name -in @('title','summary','compaction') }
  if ($hidden) {
    Write-Host ""
    Write-Host "  Hidden agents:" -ForegroundColor Gray
    foreach ($a in $hidden) {
      $m = $a.Value.model
      Write-Host "    $($a.Name): $m" -ForegroundColor Gray
    }
  }
  Write-Host ""

  $hasAgentModels = $false
  foreach ($a in $cfg.agent.PSObject.Properties) {
    if ($a.Value.model) { $hasAgentModels = $true; break }
  }
  if ($hasAgentModels) {
    Write-Host "  Mode: MULTI (per-agent models assigned)" -ForegroundColor Green
  } else {
    Write-Host "  Mode: SINGLE (all agents inherit top-level model)" -ForegroundColor Yellow
  }
  Write-Host ""
}

function Set-Multi {
  if (-not (Test-Path -LiteralPath $MultiProfile)) {
    Write-Host "Multi-model profile not found: $MultiProfile" -ForegroundColor Red
    Write-Host "Run install.ps1 first to copy profiles." -ForegroundColor Yellow
    exit 1
  }
  $profile = Get-Content -LiteralPath $MultiProfile -Raw | ConvertFrom-Json

  # Set top-level model
  $cfg.model = $profile.model
  $cfg.small_model = $profile.small_model

  # Set per-agent models
  foreach ($a in $profile.agents.PSObject.Properties) {
    $agentName = $a.Name
    $modelId = $a.Value
    if ($cfg.agent.PSObject.Properties[$agentName]) {
      $cfg.agent.$agentName | Add-Member -NotePropertyName 'model' -NotePropertyValue $modelId -Force
    } else {
      $cfg.agent | Add-Member -NotePropertyName $agentName -NotePropertyValue ([PSCustomObject]@{ model = $modelId }) -Force
    }
  }

  $cfg | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $ConfigFile -Encoding UTF8
  Write-Host "Switched to MULTI mode." -ForegroundColor Green
  Write-Host "  model: $($cfg.model)" -ForegroundColor White
  Write-Host "  Per-agent models restored from profiles/multi-models.json" -ForegroundColor White
  Write-Host ""
  Write-Host "  Restart opencode for changes to take effect." -ForegroundColor Yellow
}

function Set-Single {
  $targetModel = if ($ModelId) { $ModelId } else { $cfg.model }

  # Set top-level model
  $cfg.model = $targetModel
  $cfg.small_model = $targetModel

  # Remove per-agent model assignments
  foreach ($a in $cfg.agent.PSObject.Properties) {
    if ($a.Value.PSObject.Properties['model']) {
      $a.Value.PSObject.Properties.Remove('model')
    }
  }

  $cfg | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $ConfigFile -Encoding UTF8
  Write-Host "Switched to SINGLE mode." -ForegroundColor Yellow
  Write-Host "  model: $targetModel" -ForegroundColor White
  Write-Host "  All agents now inherit the top-level model." -ForegroundColor White
  Write-Host ""
  Write-Host "  Restart opencode for changes to take effect." -ForegroundColor Yellow
}

switch ($Action) {
  'status' { Show-Status }
  'multi'  { Set-Multi }
  'single' { Set-Single }
}

Exit-WithPause 0
