#Requires -Version 5.1
<#
.SYNOPSIS
  Post-install smoke test for OpenCode-Go Power Pack.
.DESCRIPTION
  Verifies that the installer wrote all expected files and that key tools are available.
.EXAMPLE
  .\verify.ps1
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$ConfigDir = Join-Path $env:USERPROFILE '.config\opencode'
$pass = 0
$fail = 0

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

function Check($label, $condition) {
  if ($condition) {
    Write-Host "  [PASS] $label" -ForegroundColor Green; $script:pass++
  } else {
    Write-Host "  [FAIL] $label" -ForegroundColor Red; $script:fail++
  }
}

function Test-Command($name) { return [bool](Get-Command $name -ErrorAction SilentlyContinue) }

Write-Host "`n=== OpenCode-Go Power Pack — Post-install Verification ===" -ForegroundColor Cyan

# Config files
Write-Host "`n--- Config files ---" -ForegroundColor Yellow
Check "opencode.json exists" (Test-Path -LiteralPath (Join-Path $ConfigDir 'opencode.json'))
Check "AGENTS.md exists" (Test-Path -LiteralPath (Join-Path $ConfigDir 'AGENTS.md'))
Check "manifest exists" (Test-Path -LiteralPath (Join-Path $ConfigDir '.power-pack-manifest.json'))
Check "profiles/multi-models.json exists" (Test-Path -LiteralPath (Join-Path $ConfigDir 'profiles\multi-models.json'))

# Config content
Write-Host "`n--- Config content ---" -ForegroundColor Yellow
$cfgFile = Join-Path $ConfigDir 'opencode.json'
if (Test-Path -LiteralPath $cfgFile) {
  $cfg = Get-Content -LiteralPath $cfgFile -Raw | ConvertFrom-Json
  Check "model is opencode-go/*" ($cfg.model -like 'opencode-go/*')
  Check "small_model is opencode-go/*" ($cfg.small_model -like 'opencode-go/*')
  Check "enabled_providers locked to opencode-go" ($cfg.enabled_providers -contains 'opencode-go')
  Check "compaction.prune is true" ($cfg.compaction.prune -eq $true)
  Check "setCacheKey is set" ($null -ne $cfg.provider.'opencode-go'.options.setCacheKey)
  Check "permission.bash allows *" ($cfg.permission.bash.'*' -eq 'allow')
  Check "permission.bash denies rm -rf /" ($cfg.permission.bash.'rm -rf / *' -eq 'deny')

  $mcpCount = ($cfg.mcp.PSObject.Properties | Measure-Object).Count
  Check "MCP servers configured ($mcpCount)" ($mcpCount -ge 10)

  $agentCount = ($cfg.agent.PSObject.Properties | Measure-Object).Count
  Check "Agents configured ($agentCount)" ($agentCount -ge 8)
}

# Agents
Write-Host "`n--- Agents ---" -ForegroundColor Yellow
$agentsDir = Join-Path $ConfigDir 'agents'
$expectedAgents = @('build.md','plan.md','reviewer.md','explorer.md','data-engineer.md','frontend-engineer.md','devops-engineer.md','doc-writer.md')
foreach ($a in $expectedAgents) {
  Check "agent $a" (Test-Path -LiteralPath (Join-Path $agentsDir $a))
}

# Commands
Write-Host "`n--- Commands ---" -ForegroundColor Yellow
$cmdsDir = Join-Path $ConfigDir 'commands'
$expectedCmds = @('review.md','plan.md','test.md','ship.md','debug.md','refactor.md','docs.md')
foreach ($c in $expectedCmds) {
  Check "command $c" (Test-Path -LiteralPath (Join-Path $cmdsDir $c))
}

# Skills
Write-Host "`n--- Custom skills ---" -ForegroundColor Yellow
$skillsDir = Join-Path $ConfigDir 'skills'
$customSkills = Get-ChildItem -LiteralPath $skillsDir -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -like 'custom-*' }
Check "22 custom skills installed" ($customSkills.Count -eq 22)

# Tools
Write-Host "`n--- Tools ---" -ForegroundColor Yellow
Check "git available" (Test-Command 'git')
Check "node available" (Test-Command 'node')
Check "npx available" (Test-Command 'npx')

if (Test-Command 'gh') {
  $token = & gh auth token 2>$null
  Check "gh authenticated" ($token -and $token.Trim().Length -gt 0)
} else {
  Write-Host "  [SKIP] gh CLI not found" -ForegroundColor Gray
}

# Summary
Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host "  Passed: $pass" -ForegroundColor Green
Write-Host "  Failed: $fail" -ForegroundColor $(if ($fail -gt 0) { 'Red' } else { 'Green' })
Write-Host ""

if ($fail -gt 0) {
  Write-Host "  Some checks failed. Review the output above." -ForegroundColor Yellow
  $code = 1
} else {
  Write-Host "  All checks passed. Restart opencode for changes to take effect." -ForegroundColor Green
  $code = 0
}
Exit-WithPause $code
