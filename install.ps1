#Requires -Version 5.1
<#
.SYNOPSIS
  OpenCode-Go Power Pack installer (Windows)
.DESCRIPTION
  Provisions opencode with autonomous agents, MCP servers, skills, spec-driven dev,
  and a lossless token-reduction stack — locked to the opencode-go subscription.
.PARAMETER Tier
  lean | standard | full  (default: standard)
.PARAMETER Force
  Overwrite existing files without prompting.
.PARAMETER SkipMcp
  Skip MCP package prefetch (use if npx/uvx are unavailable or slow).
.PARAMETER SkipSkills
  Skip third-party skill pack cloning (superpowers plugin still installs).
.PARAMETER DryRun
  Show what would be installed without making changes.
.EXAMPLE
  .\install.ps1
  .\install.ps1 -Tier full
  .\install.ps1 -Tier lean -SkipMcp
#>
[CmdletBinding()]
param(
  [ValidateSet('lean','standard','full')]
  [string]$Tier = 'standard',

  [switch]$Force,
  [switch]$SkipMcp,
  [switch]$SkipSkills,
  [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$HomeDir = $env:USERPROFILE
$ConfigDir = Join-Path $HomeDir '.config\opencode'
$ManifestPath = Join-Path $ConfigDir '.power-pack-manifest.json'

function Write-Step($msg) { Write-Host "`n=== $msg ===" -ForegroundColor Cyan }
function Write-Ok($msg)   { Write-Host "  [OK] $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "  [WARN] $msg" -ForegroundColor Yellow }
function Write-Err($msg)  { Write-Host "  [ERR] $msg" -ForegroundColor Red }
function Write-Info($msg) { Write-Host "  $msg" -ForegroundColor Gray }

function Test-Command($name) {
  return [bool](Get-Command $name -ErrorAction SilentlyContinue)
}

function Invoke-Safe($exe, $args) {
  if ($DryRun) { Write-Info "DRY-RUN: $exe $($args -join ' ')"; return $true }
  & $exe @args 2>&1 | ForEach-Object { Write-Info $_ }
  return $LASTEXITCODE -eq 0
}

function Exit-WithPause($code = 0) {
  Write-Host ""
  Write-Host "  Press any key to close this window..." -ForegroundColor DarkGray
  try { $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown') } catch { Read-Host "  Press Enter to close" }
  exit $code
}

# Catch any unhandled errors so the window doesn't close before the user can read them
trap {
  Write-Host ""
  Write-Host "  UNEXPECTED ERROR: $($_.Exception.Message)" -ForegroundColor Red
  $_.ScriptStackTrace | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }
  Exit-WithPause 1
}

$manifest = [ordered]@{
  version = '1.0.0'
  tier = $Tier
  installedAt = (Get-Date -Format 'o')
  files = @()
  dirs = @()
  packages = @()
}

# ── Preflight: required prerequisites ──────────────────────────────────────
Write-Step 'Preflight: required prerequisites'

$missing = @()

# git
if (Test-Command 'git') {
  $gitVer = (& git --version) 2>$null
  Write-Ok "git: $gitVer"
} else {
  $missing += 'git'
  Write-Err "git NOT found. Install from https://git-scm.com/download/win"
}

# node (v18+)
if (Test-Command 'node') {
  $nodeVer = (& node --version) 2>$null
  $nodeMajor = [int]($nodeVer -replace '^v(\d+).*', '$1')
  if ($nodeMajor -ge 18) {
    Write-Ok "node: $nodeVer"
  } else {
    $missing += 'node (v18+)'
    Write-Err "node $nodeVer is too old — need v18+. Update from https://nodejs.org"
  }
} else {
  $missing += 'node (v18+)'
  Write-Err "node NOT found. Install from https://nodejs.org"
}

# npm
if (Test-Command 'npm') {
  $npmVer = (& npm --version) 2>$null
  Write-Ok "npm: $npmVer"
} else {
  $missing += 'npm'
  Write-Err "npm NOT found. It ships with Node.js — install from https://nodejs.org"
}

# npx (ships with npm v5+)
if (Test-Command 'npx') {
  $npxVer = (& npx --version) 2>$null
  Write-Ok "npx: $npxVer"
} else {
  $missing += 'npx'
  Write-Err "npx NOT found. It ships with npm v5+ — update npm: npm install -g npm@latest"
}

# If any required prerequisite is missing, stop now with clear instructions
if ($missing.Count -gt 0) {
  Write-Host ""
  Write-Host "  MISSING PREREQUISITES: $($missing -join ', ')" -ForegroundColor Red
  Write-Host "  Install the above tools, then re-run this script." -ForegroundColor Yellow
  Write-Host ""
  Write-Host "  Press any key to close this window..." -ForegroundColor DarkGray
  Exit-WithPause 1
}

# ── Preflight: recommended prerequisites ───────────────────────────────────
Write-Step 'Preflight: recommended prerequisites (warnings only)'

$warnings = @()

# python (needed for uvx, Python MCP servers, code-review-graph, libcst)
if (Test-Command 'python') {
  $pyTest = & python -c "print('ok')" 2>&1
  if ($pyTest -eq 'ok') {
    $pyVer = (& python --version) 2>&1
    Write-Ok "python: $pyVer"
  } else {
    $warnings += 'python'
    Write-Warn "python found but doesn't work (likely the Microsoft Store stub). Install from https://www.python.org/downloads/"
    Write-Warn "  Without python: no uvx, no Python MCP servers (fetch, time, git-utils),"
    Write-Warn "  no code-review-graph. Significant functionality lost."
  }
} else {
  $warnings += 'python'
  Write-Warn "python NOT found. Install from https://www.python.org/downloads/"
  Write-Warn "  Without python: no uvx, no Python MCP servers (fetch, time, git-utils),"
  Write-Warn "  no code-review-graph, no libcst. Significant functionality lost."
}

# uvx (needed for Python MCP servers, ast-outline, specify-cli)
if (Test-Command 'uvx') {
  $uvxVer = (& uvx --version) 2>$null
  Write-Ok "uvx: $uvxVer"
} else {
  $warnings += 'uvx'
  Write-Warn "uvx NOT found. Install with: pip install uv"
  Write-Warn "  Without uvx: no Python MCP servers, no ast-outline, no GitHub Spec Kit."
  $SkipMcp = $true
}

# gh CLI (needed for GitHub MCP token auto-injection)
if (Test-Command 'gh') {
  $ghVer = (& gh --version 2>$null | Select-Object -First 1)
  Write-Ok "gh: $ghVer"
  # Check if authenticated
  $ghAuth = & gh auth status 2>&1
  if ($LASTEXITCODE -eq 0) {
    Write-Ok "gh: authenticated"
  } else {
    $warnings += 'gh-auth'
    Write-Warn "gh CLI found but NOT authenticated. Run: gh auth login"
    Write-Warn "  Without auth: GitHub MCP token will use {env:GITHUB_TOKEN} placeholder."
  }
} else {
  $warnings += 'gh'
  Write-Warn "gh CLI NOT found. Install from https://cli.github.com/"
  Write-Warn "  Without gh: GitHub MCP token will use {env:GITHUB_TOKEN} placeholder."
}

# bun (optional alternative JS runtime)
if (Test-Command 'bun') {
  Write-Ok "bun: found (optional)"
} else {
  Write-Info "bun not found (optional — not required for any core feature)"
}

if (-not (Test-Command 'npx')) { $SkipMcp = $true }

# ── Preflight: check opencode-go auth ──────────────────────────────────────
Write-Step 'Preflight: opencode-go subscription'

$authFile = Join-Path $env:USERPROFILE '.local\share\opencode\auth.json'
if (Test-Path -LiteralPath $authFile) {
  try {
    $auth = Get-Content -LiteralPath $authFile -Raw | ConvertFrom-Json
    if ($auth.'opencode-go') {
      Write-Ok "opencode-go: authenticated"
    } else {
      $warnings += 'opencode-go-auth'
      Write-Warn "opencode-go subscription NOT found in auth.json."
      Write-Warn "  Run /connect in opencode TUI, select 'OpenCode Go', paste API key from https://opencode.ai/auth"
    }
  } catch {
    $warnings += 'opencode-go-auth'
    Write-Warn "Could not read auth.json. Make sure opencode-go is connected via /connect."
  }
} else {
  $warnings += 'opencode-go-auth'
  Write-Warn "auth.json not found at $authFile"
  Write-Warn "  If you haven't used opencode yet, this is normal. Run /connect after install."
}

# ── Preflight: fix .js file association (WScript → Node) ───────────────────
Write-Step 'Preflight: .js file association'

$jsAssoc = & cmd /c "assoc .js" 2>$null
if ($jsAssoc -match 'WScript') {
  Write-Warn ".js files are associated with WScript.exe (Windows Script Host)."
  Write-Warn "  This breaks ESM MCP servers (import statements cause syntax errors)."
  if (-not $DryRun) {
    Write-Info "Fixing: associating .js with Node.js..."
    & cmd /c "assoc .js=JSFile" 2>$null
    $nodePath = (Get-Command node -ErrorAction SilentlyContinue).Source
    if ($nodePath) {
      & cmd /c "ftype JSFile=`"$nodePath`" `"%1`" %*" 2>$null
      Write-Ok ".js now associated with Node.js"
    } else {
      Write-Warn "Could not find node path — fix manually: ftype JSFile=node.exe %1 %*"
    }
  }
} else {
  Write-Ok ".js file association is not WScript (good)"
}

# ── Backup existing config ─────────────────────────────────────────────────
Write-Step 'Backup existing config'

$ConfigFile = Join-Path $ConfigDir 'opencode.jsonc'
$ConfigFileJson = Join-Path $ConfigDir 'opencode.json'
$ExistingConfig = $null
foreach ($cf in @($ConfigFile, $ConfigFileJson)) {
  if (Test-Path -LiteralPath $cf) {
    $ExistingConfig = $cf
    break
  }
}

if ($ExistingConfig) {
  $ts = Get-Date -Format 'yyyyMMdd-HHmmss'
  $BackupPath = Join-Path $ConfigDir "opencode.json.backup-$ts"
  if (-not $DryRun) {
    if (-not (Test-Path -LiteralPath $ConfigDir)) { New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null }
    Copy-Item -LiteralPath $ExistingConfig -Destination $BackupPath -Force
    $manifest.files += $BackupPath
  }
  Write-Ok "Backed up existing config to $BackupPath"
} else {
  Write-Info 'No existing opencode config found — fresh install.'
}

# ── Create directory tree ──────────────────────────────────────────────────
Write-Step 'Create directory tree'

$dirs = @('agents','commands','skills','profiles','scripts')
foreach ($d in $dirs) {
  $p = Join-Path $ConfigDir $d
  if (-not $DryRun) {
    if (-not (Test-Path -LiteralPath $p)) { New-Item -ItemType Directory -Path $p -Force | Out-Null }
    $manifest.dirs += $p
  }
  Write-Ok "dir: $p"
}

# ── Write opencode.json ────────────────────────────────────────────────────
Write-Step 'Write opencode.json'

$targetConfig = Join-Path $ConfigDir 'opencode.json'
if (-not $DryRun) {
  $srcConfig = Join-Path $ScriptDir 'opencode.json'
  $raw = Get-Content -LiteralPath $srcConfig -Raw
  # Strip // comments (JSONC) before parsing — PowerShell 5.1 ConvertFrom-Json doesn't support comments
  $raw = ($raw -split "`r?`n" | Where-Object { $_ -notmatch '^\s*//' }) -join "`r`n"
  $cfg = $raw | ConvertFrom-Json

  # Strip _comment fields
  $cfg.PSObject.Properties | Where-Object { $_.Name -like '_comment*' } | ForEach-Object {
    $cfg.PSObject.Properties.Remove($_.Name)
  }

  # Tier: adjust MCP servers
  if ($Tier -eq 'lean') {
    # Remove code-review-graph, pakt from MCP (lean = 10 servers)
    @('code-review-graph','pakt') | ForEach-Object {
      if ($cfg.mcp.PSObject.Properties[$_]) { $cfg.mcp.PSObject.Properties.Remove($_) }
    }
  } elseif ($Tier -eq 'full') {
    # Add arbor, provenant, headroom to MCP
    $cfg.mcp | Add-Member -NotePropertyName 'arbor' -NotePropertyValue ([PSCustomObject]@{
      type = 'local'; command = @('cmd','/c','arbor'); enabled = $true; timeout = 30000
    }) -Force
    $cfg.mcp | Add-Member -NotePropertyName 'provenant' -NotePropertyValue ([PSCustomObject]@{
      type = 'local'; command = @('cmd','/c','provenant','serve','.'); enabled = $true; timeout = 30000
    }) -Force
    $cfg.mcp | Add-Member -NotePropertyName 'headroom' -NotePropertyValue ([PSCustomObject]@{
      type = 'local'; command = @('cmd','/c','headroom','mcp'); enabled = $true; timeout = 30000
    }) -Force
  }

  # Inject GitHub token if gh is available
  if (Test-Command 'gh') {
    $token = & gh auth token 2>$null
    if ($token -and $token.Trim()) {
      $cfg.mcp.github.environment.GITHUB_TOKEN = $token.Trim()
      Write-Ok 'GitHub token injected from gh CLI'
    } else {
      Write-Warn 'gh auth token returned empty — using {env:GITHUB_TOKEN} placeholder'
    }
  }

  $cfg | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $targetConfig -Encoding UTF8
  $manifest.files += $targetConfig
}
Write-Ok "config: $targetConfig (tier=$Tier)"

# ── Copy agents ────────────────────────────────────────────────────────────
Write-Step 'Copy agents'

$agentSrc = Join-Path $ScriptDir 'agents'
if (Test-Path -LiteralPath $agentSrc) {
  $agentDest = Join-Path $ConfigDir 'agents'
  Get-ChildItem -LiteralPath $agentSrc -Filter '*.md' | ForEach-Object {
    $dest = Join-Path $agentDest $_.Name
    if (-not $DryRun) { Copy-Item -LiteralPath $_.FullName -Destination $dest -Force; $manifest.files += $dest }
    Write-Ok "agent: $($_.Name)"
  }
}

# ── Copy commands ──────────────────────────────────────────────────────────
Write-Step 'Copy commands'

$cmdSrc = Join-Path $ScriptDir 'commands'
if (Test-Path -LiteralPath $cmdSrc) {
  $cmdDest = Join-Path $ConfigDir 'commands'
  Get-ChildItem -LiteralPath $cmdSrc -Filter '*.md' | ForEach-Object {
    $dest = Join-Path $cmdDest $_.Name
    if (-not $DryRun) { Copy-Item -LiteralPath $_.FullName -Destination $dest -Force; $manifest.files += $dest }
    Write-Ok "command: $($_.Name)"
  }
}

# ── Copy AGENTS.md ─────────────────────────────────────────────────────────
Write-Step 'Copy AGENTS.md'

$agentsMd = Join-Path $ScriptDir 'AGENTS.md'
if (Test-Path -LiteralPath $agentsMd) {
  $dest = Join-Path $ConfigDir 'AGENTS.md'
  if (-not $DryRun) { Copy-Item -LiteralPath $agentsMd -Destination $dest -Force; $manifest.files += $dest }
  Write-Ok "AGENTS.md: $dest"
}

# ── Copy profiles ──────────────────────────────────────────────────────────
Write-Step 'Copy profiles'

$profSrc = Join-Path $ScriptDir 'profiles'
if (Test-Path -LiteralPath $profSrc) {
  $profDest = Join-Path $ConfigDir 'profiles'
  Get-ChildItem -LiteralPath $profSrc -Filter '*.json' | ForEach-Object {
    $dest = Join-Path $profDest $_.Name
    if (-not $DryRun) { Copy-Item -LiteralPath $_.FullName -Destination $dest -Force; $manifest.files += $dest }
    Write-Ok "profile: $($_.Name)"
  }
}

# ── Copy custom skills ─────────────────────────────────────────────────────
Write-Step 'Copy custom skills'

$skillsSrc = Join-Path $ScriptDir 'skills'
$skillsDest = Join-Path $ConfigDir 'skills'
if (Test-Path -LiteralPath $skillsSrc) {
  Get-ChildItem -LiteralPath $skillsSrc -Directory | Where-Object { $_.Name -like 'custom-*' } | ForEach-Object {
    $dest = Join-Path $skillsDest $_.Name
    if (-not $DryRun) {
      if (Test-Path -LiteralPath $dest) { Remove-Item -LiteralPath $dest -Recurse -Force }
      Copy-Item -LiteralPath $_.FullName -Destination $dest -Recurse -Force
      $manifest.dirs += $dest
    }
    Write-Ok "skill: $($_.Name)"
  }
}

# ── Install superpowers plugin (already in opencode.json) ──────────────────
Write-Step 'Install superpowers plugin'
if (-not $DryRun) {
  Write-Info 'superpowers is configured as a git+https plugin in opencode.json.'
  Write-Info 'It will be fetched automatically when opencode starts.'
}

# ── Install third-party skill packs ────────────────────────────────────────
if (-not $SkipSkills -and $Tier -ne 'lean') {
  Write-Step "Install third-party skill packs (tier=$Tier)"

  if (Test-Command 'git') {
    # CodeRabbit skills (standard+)
    if ($Tier -in @('standard','full')) {
      $crDest = Join-Path $skillsDest 'coderabbitai'
      if (-not (Test-Path -LiteralPath $crDest) -or $Force) {
        Write-Info 'Installing CodeRabbit skills (npx skills add coderabbitai/skills)...'
        if (Test-Command 'npx') {
          $ok = Invoke-Safe 'npx' @('-y','skills','add','coderabbitai/skills')
          if ($ok) { Write-Ok 'CodeRabbit skills installed'; $manifest.dirs += $crDest }
          else { Write-Warn 'CodeRabbit skills install failed — you can retry with: npx skills add coderabbitai/skills' }
        } else {
          Write-Warn 'npx not available — skipping CodeRabbit skills'
        }
      } else { Write-Info 'CodeRabbit skills already installed' }
    }

    # Full tier: clone farmage, addyosmani, cherry-pick from skills.sh
    if ($Tier -eq 'full') {
      $packs = @(
        @{ name='farmage'; url='https://github.com/farmage/opencode-skills.git' },
        @{ name='addyosmani'; url='https://github.com/addyosmani/agent-skills.git' }
      )
      foreach ($pack in $packs) {
        $dest = Join-Path $skillsDest $pack.name
        if (-not (Test-Path -LiteralPath $dest) -or $Force) {
          Write-Info "Cloning $($pack.name)..."
          $ok = Invoke-Safe 'git' @('clone','--depth','1',$pack.url,$dest)
          if ($ok) { Write-Ok "$($pack.name) cloned"; $manifest.dirs += $dest }
          else { Write-Warn "$($pack.name) clone failed" }
        } else { Write-Info "$($pack.name) already installed" }
      }

      # Cherry-picked skills from skills.sh
      $cherryPicks = @(
        'anthropics/skills/frontend-design',
        'mattpocock/skills/tdd',
        'mattpocock/skills/diagnose',
        'mattpocock/skills/triage',
        'mattpocock/skills/improve-codebase-architecture',
        'vercel-labs/next-skills/next-best-practices',
        'vercel-labs/agent-skills/vercel-react-best-practices',
        'supabase/agent-skills/supabase-postgres-best-practices',
        'shadcn/ui/shadcn',
        'anthropics/skills/skill-creator'
      )
      if (Test-Command 'npx') {
        foreach ($skill in $cherryPicks) {
          Write-Info "npx skills add $skill"
          $ok = Invoke-Safe 'npx' @('-y','skills','add',$skill)
          if ($ok) { Write-Ok "skill: $skill" } else { Write-Warn "skill: $skill (failed, non-fatal)" }
        }
      }
    }
  } else {
    Write-Warn 'git not available — skipping third-party skill packs'
  }
} elseif ($SkipSkills) {
  Write-Step 'Skip third-party skill packs (-SkipSkills)'
} else {
  Write-Step 'Skip third-party skill packs (lean tier)'
}

# ── Prefetch MCP packages ──────────────────────────────────────────────────
if (-not $SkipMcp) {
  Write-Step "Prefetch MCP packages (tier=$Tier)"

  $npmMcps = @(
    '@playwright/mcp@latest',
    '@modelcontextprotocol/server-github',
    '@modelcontextprotocol/server-sequential-thinking',
    '@modelcontextprotocol/server-filesystem',
    '@modelcontextprotocol/server-memory',
    'repomix@latest',
    '@sriinnu/pakt'
  )
  if ($Tier -eq 'full') { $npmMcps += @('headroom-ai') }

  foreach ($pkg in $npmMcps) {
    Write-Info "Prefetching $pkg..."
    $ok = Invoke-Safe 'npx' @('-y',$pkg,'--help')
    if ($ok) { Write-Ok $pkg } else { Write-Warn "$pkg prefetch failed (non-fatal — will fetch on first use)" }
    $manifest.packages += $pkg
  }

  $uvxMcps = @('mcp-server-fetch','mcp-server-time','mcp-server-git')
  if (Test-Command 'uvx') {
    foreach ($pkg in $uvxMcps) {
      Write-Info "Prefetching $pkg..."
      $ok = Invoke-Safe 'uvx' @($pkg,'--help')
      if ($ok) { Write-Ok $pkg } else { Write-Warn "$pkg prefetch failed (non-fatal)" }
      $manifest.packages += $pkg
    }
  } else {
    Write-Warn 'uvx not available — skipping Python MCP prefetch'
  }

  # code-review-graph (pip package, NOT npm)
  if ($Tier -in @('standard','full')) {
    Write-Info 'Installing code-review-graph via pip...'
    if (Test-Command 'pip') {
      $ok = Invoke-Safe 'pip' @('install','code-review-graph')
      if ($ok) {
        Write-Ok 'code-review-graph installed via pip'
        $manifest.packages += 'code-review-graph'
      } else {
        Write-Warn 'code-review-graph pip install failed — install manually: pip install code-review-graph'
      }
    } elseif (Test-Command 'uvx') {
      Write-Info 'pip not found, trying uvx...'
      $ok = Invoke-Safe 'uvx' @('--from','code-review-graph','code-review-graph','--help')
      if ($ok) { Write-Ok 'code-review-graph available via uvx'; $manifest.packages += 'code-review-graph' }
      else { Write-Warn 'code-review-graph install failed — install manually: pip install code-review-graph' }
    } else {
      Write-Warn 'Neither pip nor uvx available — code-review-graph requires Python. Install: pip install code-review-graph'
    }
  }
} else {
  Write-Step 'Skip MCP prefetch (-SkipMcp)'
}

# ── Install external CLIs ──────────────────────────────────────────────────
if ($Tier -in @('standard','full')) {
  Write-Step "Install external CLIs (tier=$Tier)"

  # ast-outline
  if (Test-Command 'uvx') {
    Write-Info 'Installing ast-outline...'
    $ok = Invoke-Safe 'uvx' @('ast-outline','--help')
    if ($ok) { Write-Ok 'ast-outline available via uvx'; $manifest.packages += 'ast-outline' }
    else { Write-Warn 'ast-outline install failed' }
  } else { Write-Warn 'uvx not available — ast-outline requires uv/uvx' }

  # ast-grep
  if (Test-Command 'npm') {
    Write-Info 'Installing ast-grep...'
    $ok = Invoke-Safe 'npm' @('install','-g','@ast-grep/cli')
    if ($ok) { Write-Ok 'ast-grep installed'; $manifest.packages += '@ast-grep/cli' }
    else { Write-Warn 'ast-grep install failed' }
  }

  # gtr (git-worktree-runner) — needs git
  if (Test-Command 'git') {
    Write-Info 'Installing gtr (git-worktree-runner)...'
    $gtrScript = Join-Path $ScriptDir '..' 'git-worktree-runner' 'install.sh'
    # On Windows, gtr may need WSL. Print instructions.
    Write-Warn 'gtr (git-worktree-runner) on native Windows may need WSL.'
    Write-Warn 'Install manually: curl -fsSL https://raw.githubusercontent.com/coderabbitai/git-worktree-runner/main/install.sh | sh'
    Write-Warn 'Then: git gtr config set gtr.ai.default opencode'
    $manifest.packages += 'gtr (manual)'
  }
}

if ($Tier -eq 'full') {
  # jscodeshift, libcst, aider
  if (Test-Command 'npm') {
    Write-Info 'Installing jscodeshift...'
    $ok = Invoke-Safe 'npm' @('install','-g','jscodeshift')
    if ($ok) { Write-Ok 'jscodeshift installed'; $manifest.packages += 'jscodeshift' }
  }
  if (Test-Command 'pip') {
    Write-Info 'Installing libcst...'
    $ok = Invoke-Safe 'pip' @('install','libcst')
    if ($ok) { Write-Ok 'libcst installed'; $manifest.packages += 'libcst' }
    Write-Info 'Installing aider...'
    $ok = Invoke-Safe 'pip' @('install','aider-chat')
    if ($ok) { Write-Ok 'aider installed'; $manifest.packages += 'aider-chat' }
  }
}

# ── Install GitHub Spec Kit (standard+) ────────────────────────────────────
if ($Tier -in @('standard','full')) {
  Write-Step 'Install GitHub Spec Kit'
  if (Test-Command 'uvx') {
    Write-Info 'Installing specify-cli...'
    $ok = Invoke-Safe 'uvx' @('specify-cli','--help')
    if ($ok) { Write-Ok 'specify-cli available via uvx'; $manifest.packages += 'specify-cli' }
    else { Write-Warn 'specify-cli install failed — you can install with: uv tool install specify-cli' }
    Write-Info 'Per-project: cd your-project; specify init . --integration opencode'
  } else {
    Write-Warn 'uvx not available — install specify-cli with: uv tool install specify-cli'
  }
}

# ── Install skillgate (standard+) ──────────────────────────────────────────
if ($Tier -in @('standard','full')) {
  Write-Step 'Install skillgate (DoD gate)'
  if (Test-Command 'npm') {
    Write-Info 'skillgate is a TypeScript pre-commit/CI gate.'
    Write-Info 'Install per-project: see https://github.com/renezander030/skillgate'
    $manifest.packages += 'skillgate (per-project)'
  }
}

# ── Write manifest ─────────────────────────────────────────────────────────
Write-Step 'Write manifest'
if (-not $DryRun) {
  $manifest | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $ManifestPath -Encoding UTF8
  Write-Ok "Manifest: $ManifestPath"
}

# ── Summary ────────────────────────────────────────────────────────────────
Write-Step 'Summary'
Write-Host ""
Write-Host "  Tier:           $Tier" -ForegroundColor White
Write-Host "  Config:         $targetConfig" -ForegroundColor White
Write-Host "  Agents:         8" -ForegroundColor White
Write-Host "  Commands:       7" -ForegroundColor White
Write-Host "  Custom skills:  22" -ForegroundColor White
$mcpCount = if ($Tier -eq 'lean') { 10 } elseif ($Tier -eq 'standard') { 12 } else { 15 }
Write-Host "  MCP servers:    $mcpCount" -ForegroundColor White
Write-Host "  Manifest:       $ManifestPath" -ForegroundColor White
Write-Host ""
Write-Host "  IMPORTANT: Restart opencode for changes to take effect." -ForegroundColor Yellow
Write-Host "  Config is loaded once at startup and is not hot-reloaded." -ForegroundColor Yellow
Write-Host ""
Write-Host "  To revert: .\uninstall.ps1 -Full" -ForegroundColor Gray
Write-Host "  To toggle models: .\toggle-models.ps1 status" -ForegroundColor Gray
Exit-WithPause 0
