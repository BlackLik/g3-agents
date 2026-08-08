#!/usr/bin/env pwsh
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent $PSScriptRoot

$OpencodeFiles = 'flow.md', 'subflow.md', 'player.md', 'coach.md'
$OpencodeRefFiles = 'coach-reference.md', 'flow-reference.md'
$ClaudeFiles = 'flow.md', 'player.md', 'coach.md'
$ClaudeRefFiles = 'coach-reference.md', 'flow-reference.md'

function Usage {
    [Console]::Error.WriteLine("Usage: scripts/install.ps1 <opencode|claude|all> [--global|--local]")
    exit 1
}

if ($args.Count -lt 1) { Usage }
$tool = $args[0]
$target = if ($args.Count -ge 2) { $args[1] } else { '--global' }
if ($tool -notin 'opencode', 'claude', 'all') { Usage }
if ($target -notin '--global', '--local') { Usage }

function Install-One($src, $dest, $files) {
    New-Item -ItemType Directory -Force -Path $dest | Out-Null
    if ((Resolve-Path $src).Path -eq (Resolve-Path $dest).Path) {
        Write-Output "skip: $src == $dest"
        return
    }
    foreach ($f in $files) {
        Copy-Item -LiteralPath (Join-Path $src $f) -Destination (Join-Path $dest $f)
    }
    Write-Output "installed: $dest"
}

if ($tool -in 'opencode', 'all') {
    $base = if ($target -eq '--global') { Join-Path $HOME '.config/opencode' } else { './.opencode' }
    Install-One (Join-Path $RepoRoot '.opencode/agents') (Join-Path $base 'agents') $OpencodeFiles
    Install-One (Join-Path $RepoRoot '.opencode/reference') (Join-Path $base 'reference') $OpencodeRefFiles
}

if ($tool -in 'claude', 'all') {
    $base = if ($target -eq '--global') { Join-Path $HOME '.claude' } else { './.claude' }
    Install-One (Join-Path $RepoRoot '.claude/agents') (Join-Path $base 'agents') $ClaudeFiles
    Install-One (Join-Path $RepoRoot '.claude/reference') (Join-Path $base 'reference') $ClaudeRefFiles
}
