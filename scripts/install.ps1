#requires -Version 5.1
<#
.SYNOPSIS
Install MyWorkSkills into an Agent Skill discovery directory.
.EXAMPLE
./scripts/install.ps1 -Target OpenCode -Scope User
.EXAMPLE
./scripts/install.ps1 -Target All -Scope Project -ProjectPath 'D:\Work\Demo'
.EXAMPLE
./scripts/install.ps1 -Target Codex -Scope User -Names industrial-code-review,engineering-constraints
#>
[CmdletBinding()]
param(
    [ValidateSet('OpenCode', 'Codex', 'Claude', 'All')]
    [string]$Target = 'OpenCode',

    [ValidateSet('User', 'Project')]
    [string]$Scope = 'User',

    [string]$ProjectPath = (Get-Location).Path,

    [string[]]$Names = @(),

    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path -Parent $PSScriptRoot
$sourceRoot = Join-Path $repositoryRoot 'skills'
if (-not (Test-Path -LiteralPath $sourceRoot -PathType Container)) {
    throw "Missing skill source directory: $sourceRoot"
}
if ($Scope -eq 'Project' -and -not (Test-Path -LiteralPath $ProjectPath -PathType Container)) {
    throw "Project directory does not exist: $ProjectPath"
}

$targets = if ($Target -eq 'All') { @('OpenCode', 'Codex', 'Claude') } else { @($Target) }

function Get-InstallDirectory([string]$Agent, [string]$Mode, [string]$Project) {
    if ($Mode -eq 'Project') {
        $base = (Resolve-Path -LiteralPath $Project).Path
        switch ($Agent) {
            'OpenCode' { return (Join-Path $base '.opencode/skills') }
            'Codex'    { return (Join-Path $base '.agents/skills') }
            'Claude'   { return (Join-Path $base '.claude/skills') }
        }
    }
    switch ($Agent) {
        'OpenCode' { return (Join-Path $HOME '.config/opencode/skills') }
        'Codex'    { return (Join-Path $HOME '.agents/skills') }
        'Claude'   { return (Join-Path $HOME '.claude/skills') }
    }
}

$allSkills = @(Get-ChildItem -LiteralPath $sourceRoot -Directory | Where-Object {
    Test-Path -LiteralPath (Join-Path $_.FullName 'SKILL.md') -PathType Leaf
})
if ($Names.Count -gt 0) {
    $unknown = @($Names | Where-Object { $_ -notin $allSkills.Name })
    if ($unknown.Count -gt 0) { throw "Unknown skills: $($unknown -join ', ')" }
    $allSkills = @($allSkills | Where-Object { $_.Name -in $Names })
}

[int]$installed = 0
[int]$skipped = 0
foreach ($agent in $targets) {
    $targetRoot = Get-InstallDirectory $agent $Scope $ProjectPath
    New-Item -ItemType Directory -Path $targetRoot -Force | Out-Null

    foreach ($skill in $allSkills) {
        $destination = Join-Path $targetRoot $skill.Name
        if (Test-Path -LiteralPath $destination) {
            if (-not $Force) {
                Write-Host "SKIP  [$agent] $($skill.Name): already exists"
                $skipped++
                continue
            }
            # Preserve previous installation before an explicit replacement.
            $stamp = Get-Date -Format 'yyyyMMdd-HHmmss-fff'
            $backup = "$destination.backup-$stamp"
            Move-Item -LiteralPath $destination -Destination $backup
            Write-Host "BACKUP [$agent] $backup"
        }
        Copy-Item -LiteralPath $skill.FullName -Destination $destination -Recurse
        Write-Host "OK    [$agent] $($skill.Name) -> $destination"
        $installed++
    }
}
Write-Host "Finished. Installed: $installed. Skipped: $skipped."
Write-Host 'Restart or reload your Agent if Skills are not immediately discovered.'
