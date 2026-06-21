#Requires -Version 5.1
<#
.SYNOPSIS
  Uninstall OpenCode-Go Power Pack and restore opencode to stock configuration.
.DESCRIPTION
  Reads the manifest written by install.ps1 to safely remove only what was installed.
  Restores the backup config if available, otherwise writes a minimal stock config.
.PARAMETER KeepBackups
  Restore config but preserve backup files.
.PARAMETER RemoveSkills
  Also remove installed skill packs (superpowers, coderabbitai, farmage, addyosmani, custom-*).
.PARAMETER RemoveMcpDeps
  Also uninstall npx/uvx MCP packages (npm uninstall -g, uvx cache clear).
.PARAMETER Full
  Everything: restore config + remove all skills/MCP/agents/commands/AGENTS.md/scripts.
.PARAMETER DryRun
  Show what would be removed without doing it.
.EXAMPLE
  .\uninstall.ps1                # restore config, keep skills
  .\uninstall.ps1 -Full          # complete removal
  .\uninstall.ps1 -Full -DryRun  # preview full removal
#>
[CmdletBinding()]
param(
  [switch]$KeepBackups,
  [switch]$RemoveSkills,
  [switch]$RemoveMcpDeps,
  [switch]$Full,
  [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$ConfigDir = Join-Path $env:USERPROFILE '.config\opencode'
$ManifestPath = Join-Path $ConfigDir '.power-pack-manifest.json'

if ($Full) { $RemoveSkills = $true; $RemoveMcpDeps = $true }

function Write-Step($msg) { Write-Host "`n=== $msg ===" -ForegroundColor Cyan }
function Write-Ok($msg)   { Write-Host "  [OK] $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "  [WARN] $msg" -ForegroundColor Yellow }
function Write-Info($msg) { Write-Host "  $msg" -ForegroundColor Gray }
function Write-Err($msg)  { Write-Host "  [ERR] $msg" -ForegroundColor Red }

if (-not (Test-Path -LiteralPath $ManifestPath)) {
  Write-Err "Manifest not found: $ManifestPath"
  Write-Err "Cannot safely uninstall without the manifest."
  Write-Err "You can manually delete ~/.config/opencode/ to reset to stock."
  exit 1
}

$manifest = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
$removedFiles = 0
$removedDirs = 0

# ── Restore backup config ──────────────────────────────────────────────────
Write-Step 'Restore config'

$configFile = Join-Path $ConfigDir 'opencode.json'
$backups = Get-ChildItem -LiteralPath $ConfigDir -Filter 'opencode.json.backup-*' -ErrorAction SilentlyContinue |
  Sort-Object Name -Descending

if ($backups -and $backups.Count -gt 0) {
  $latestBackup = $backups[0].FullName
  if (-not $DryRun) {
    Copy-Item -LiteralPath $latestBackup -Destination $configFile -Force
  }
  Write-Ok "Restored config from backup: $($backups[0].Name)"

  if (-not $KeepBackups) {
    foreach ($b in $backups) {
      if (-not $DryRun) { Remove-Item -LiteralPath $b.FullName -Force }
      Write-Info "Removed backup: $($b.Name)"
    }
  } else {
    Write-Info 'Keeping backup files (-KeepBackups)'
  }
} else {
  Write-Warn 'No backup found — writing minimal stock config.'
  $stock = @{ '$schema' = 'https://opencode.ai/config.json' }
  if (-not $DryRun) {
    $stock | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $configFile -Encoding UTF8
  }
  Write-Ok 'Wrote minimal stock config.'
}

# ── Remove agents ──────────────────────────────────────────────────────────
Write-Step 'Remove agents'
$agentsDir = Join-Path $ConfigDir 'agents'
$expectedAgents = @('build.md','plan.md','reviewer.md','explorer.md','data-engineer.md','frontend-engineer.md','devops-engineer.md','doc-writer.md')
foreach ($a in $expectedAgents) {
  $p = Join-Path $agentsDir $a
  if (Test-Path -LiteralPath $p) {
    if (-not $DryRun) { Remove-Item -LiteralPath $p -Force }
    Write-Ok "Removed: agents/$a"; $removedFiles++
  }
}

# ── Remove commands ────────────────────────────────────────────────────────
Write-Step 'Remove commands'
$cmdsDir = Join-Path $ConfigDir 'commands'
$expectedCmds = @('review.md','plan.md','test.md','ship.md','debug.md','refactor.md','docs.md')
foreach ($c in $expectedCmds) {
  $p = Join-Path $cmdsDir $c
  if (Test-Path -LiteralPath $p) {
    if (-not $DryRun) { Remove-Item -LiteralPath $p -Force }
    Write-Ok "Removed: commands/$c"; $removedFiles++
  }
}

# ── Remove AGENTS.md ───────────────────────────────────────────────────────
Write-Step 'Remove AGENTS.md'
$agentsMd = Join-Path $ConfigDir 'AGENTS.md'
if (Test-Path -LiteralPath $agentsMd) {
  if (-not $DryRun) { Remove-Item -LiteralPath $agentsMd -Force }
  Write-Ok 'Removed: AGENTS.md'; $removedFiles++
}

# ── Remove profiles ────────────────────────────────────────────────────────
Write-Step 'Remove profiles'
$profDir = Join-Path $ConfigDir 'profiles'
if (Test-Path -LiteralPath $profDir) {
  if (-not $DryRun) { Remove-Item -LiteralPath $profDir -Recurse -Force }
  Write-Ok 'Removed: profiles/'; $removedDirs++
}

# ── Remove custom skills ───────────────────────────────────────────────────
if ($RemoveSkills) {
  Write-Step 'Remove skills'
  $skillsDir = Join-Path $ConfigDir 'skills'
  if (Test-Path -LiteralPath $skillsDir) {
    # Remove custom-* skills
    Get-ChildItem -LiteralPath $skillsDir -Directory -ErrorAction SilentlyContinue |
      Where-Object { $_.Name -like 'custom-*' } | ForEach-Object {
        if (-not $DryRun) { Remove-Item -LiteralPath $_.FullName -Recurse -Force }
        Write-Ok "Removed skill: $($_.Name)"; $removedDirs++
      }

    # Remove third-party skill packs (if present)
    $thirdParty = @('coderabbitai','farmage','addyosmani','obra-superpowers-skills','superpowers-lab')
    foreach ($tp in $thirdParty) {
      $p = Join-Path $skillsDir $tp
      if (Test-Path -LiteralPath $p) {
        if (-not $DryRun) { Remove-Item -LiteralPath $p -Recurse -Force }
        Write-Ok "Removed skill pack: $tp"; $removedDirs++
      }
    }

    # Remove cherry-picked skills (from npx skills add)
    $cherryPicked = @('frontend-design','tdd','diagnose','triage','improve-codebase-architecture','next-best-practices','vercel-react-best-practices','supabase-postgres-best-practices','shadcn','skill-creator')
    foreach ($cp in $cherryPicked) {
      $p = Join-Path $skillsDir $cp
      if (Test-Path -LiteralPath $p) {
        if (-not $DryRun) { Remove-Item -LiteralPath $p -Recurse -Force }
        Write-Ok "Removed cherry-picked skill: $cp"; $removedDirs++
      }
    }

    # If skills dir is now empty, remove it
    $remaining = Get-ChildItem -LiteralPath $skillsDir -ErrorAction SilentlyContinue
    if (-not $remaining) {
      if (-not $DryRun) { Remove-Item -LiteralPath $skillsDir -Recurse -Force }
      Write-Ok 'Removed empty: skills/'; $removedDirs++
    }
  }
} else {
  Write-Step 'Keep skills (-RemoveSkills not set)'
  Write-Info 'Skill packs will remain installed.'
}

# ── Remove MCP packages ────────────────────────────────────────────────────
if ($RemoveMcpDeps) {
  Write-Step 'Remove MCP packages (npm global)'
  $npmPkgs = @(
    '@playwright/mcp','@modelcontextprotocol/server-github',
    '@modelcontextprotocol/server-sequential-thinking',
    '@modelcontextprotocol/server-filesystem','@modelcontextprotocol/server-memory',
    'think-mcp-server','repomix','@sriinnu/pakt','@ast-grep/cli',
    'jscodeshift','code-review-graph','headroom-ai'
  )
  foreach ($pkg in $npmPkgs) {
    if (Get-Command npm -ErrorAction SilentlyContinue) {
      Write-Info "npm uninstall -g $pkg"
      if (-not $DryRun) { & npm uninstall -g $pkg 2>&1 | Out-Null }
    }
  }
  Write-Ok 'npm global packages removed (if installed)'
} else {
  Write-Step 'Keep MCP packages (-RemoveMcpDeps not set)'
}

# ── Remove manifest ────────────────────────────────────────────────────────
Write-Step 'Remove manifest'
if (Test-Path -LiteralPath $ManifestPath) {
  if (-not $DryRun) { Remove-Item -LiteralPath $ManifestPath -Force }
  Write-Ok 'Removed: .power-pack-manifest.json'
}

# ── Remove scripts dir (if empty) ──────────────────────────────────────────
$scriptsDir = Join-Path $ConfigDir 'scripts'
if (Test-Path -LiteralPath $scriptsDir) {
  $remaining = Get-ChildItem -LiteralPath $scriptsDir -ErrorAction SilentlyContinue
  if (-not $remaining) {
    if (-not $DryRun) { Remove-Item -LiteralPath $scriptsDir -Recurse -Force }
    Write-Ok 'Removed empty: scripts/'
  }
}

# ── Summary ────────────────────────────────────────────────────────────────
Write-Step 'Summary'
Write-Host ""
Write-Host "  Files removed:  $removedFiles" -ForegroundColor White
Write-Host "  Dirs removed:   $removedDirs" -ForegroundColor White
Write-Host "  Config:         restored to stock (or backup)" -ForegroundColor White
Write-Host ""
Write-Host "  IMPORTANT: Restart opencode for changes to take effect." -ForegroundColor Yellow
Write-Host ""
if ($DryRun) {
  Write-Host "  (DRY-RUN: no changes were actually made)" -ForegroundColor Magenta
}
Write-Host ""
Write-Host "  Press any key to close this window..." -ForegroundColor DarkGray
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
