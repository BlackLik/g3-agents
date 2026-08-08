#!/usr/bin/env pwsh
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$OpencodeFiles = 'flow.md', 'subflow.md', 'player.md', 'coach.md'
$OpencodeRefFiles = 'coach-reference.md', 'flow-reference.md'
$ClaudeFiles = 'flow.md', 'player.md', 'coach.md'
$ClaudeRefFiles = 'coach-reference.md', 'flow-reference.md'

function Usage {
    [Console]::Error.WriteLine("Usage: scripts/uninstall.ps1 <opencode|claude|all> [--global|--local]")
    exit 1
}

if ($args.Count -lt 1) { Usage }
$tool = $args[0]
$target = if ($args.Count -ge 2) { $args[1] } else { '--global' }
if ($tool -notin 'opencode', 'claude', 'all') { Usage }
if ($target -notin '--global', '--local') { Usage }

function Uninstall-One($dest, $files) {
    foreach ($f in $files) {
        $p = Join-Path $dest $f
        if (Test-Path -LiteralPath $p) { Remove-Item -Force -LiteralPath $p }
    }
    Write-Output "uninstalled: $dest"
}

if ($tool -in 'opencode', 'all') {
    $base = if ($target -eq '--global') { Join-Path $HOME '.config/opencode' } else { './.opencode' }
    Uninstall-One (Join-Path $base 'agents') $OpencodeFiles
    Uninstall-One (Join-Path $base 'reference') $OpencodeRefFiles
}

if ($tool -in 'claude', 'all') {
    $base = if ($target -eq '--global') { Join-Path $HOME '.claude' } else { './.claude' }
    Uninstall-One (Join-Path $base 'agents') $ClaudeFiles
    Uninstall-One (Join-Path $base 'reference') $ClaudeRefFiles
}
