---
name: custom-windows-powershell-tooling
description: Use ONLY when running on Windows (PowerShell 5.1). Covers PS 5.1 idioms, command chaining, native executable invocation, string interpolation, alias avoidance. Trigger on: Windows, PowerShell, ps1, cmd, native, executable,&&, chaining.
---

# Windows PowerShell Tooling

## When this applies

Use this skill when the operating system is Windows and the shell is PowerShell 5.1. If you're on macOS/Linux, ignore this skill.

## Command chaining

**Do NOT use `&&`** — PowerShell 5.1 does not support it.

```powershell
# CORRECT — chain dependent commands
cmd1; if ($?) { cmd2 }

# CORRECT — run sequentially, don't care if earlier fails
cmd1; cmd2

# WRONG — && is not supported in PS 5.1
cmd1 && cmd2
```

## Prefer full cmdlet names over aliases

```powershell
# CORRECT
Get-ChildItem -LiteralPath "."
Set-Content -LiteralPath "file.txt" -Value "content"
New-Item -ItemType Directory -Path "tmp"
Remove-Item -LiteralPath "file.txt"

# WRONG — aliases
ls "."
echo "content" > file.txt
touch file.txt
rm file.txt
```

## String interpolation

```powershell
# Double quotes — interpolated
"Hello $name"
"Result: $(Get-Process | Select-Object -First 1)"

# Single quotes — verbatim (no interpolation)
'Hello $name'  # literal: Hello $name
```

## Subexpressions and arrays

```powershell
# Subexpression
$(Get-Date -Format 'yyyy-MM-dd')

# Array expression
@(1, 2, 3)
```

## Calling native executables with spaces in path

```powershell
# Use the call operator &
& "C:\Program Files\MyApp\app.exe" --flag

# Without spaces, & is optional
git status
```

## Escaping special characters

Use the backtick character:

```powershell
`$  # literal dollar sign
`"  # literal double quote
``  # literal backtick
```

## Common pitfalls

- `Test-Path -LiteralPath <path>` — always use `-LiteralPath` for paths with special chars.
- `Get-Content` returns an array of lines by default. Use `-Raw` for the full string.
- PowerShell variables are case-insensitive: `$Foo` and `$foo` are the same.
- `Select-Object -First N` is fine, but don't use it to truncate tool output — the tool already handles that.
