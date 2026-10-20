#requires -Version 5.1
<#
Checks file naming and metadata against basic Agent Skills conventions.
Does not claim that an Agent client has successfully loaded a skill.
#>
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = Join-Path (Split-Path -Parent $PSScriptRoot) 'skills'
if (-not (Test-Path -LiteralPath $root -PathType Container)) {
    throw "Missing skills directory: $root"
}
$directories = @(Get-ChildItem -LiteralPath $root -Directory)
$seen = @{}
$errors = New-Object System.Collections.Generic.List[string]

foreach ($directory in $directories) {
    $path = Join-Path $directory.FullName 'SKILL.md'
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        $errors.Add("Missing SKILL.md: $($directory.Name)")
        continue
    }
    $content = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
    $head = [regex]::Match($content, '(?s)\A---\r?\n(.*?)\r?\n---(?:\r?\n|$)')
    if (-not $head.Success) {
        $errors.Add("Missing YAML frontmatter: $path")
        continue
    }
    $nameMatch = [regex]::Match($head.Groups[1].Value, '(?m)^name:\s*([^\r\n]+)$')
    $descriptionMatch = [regex]::Match($head.Groups[1].Value, '(?m)^description:\s*([^\r\n]+)$')
    $name = if ($nameMatch.Success) { $nameMatch.Groups[1].Value.Trim() } else { '' }
    $description = if ($descriptionMatch.Success) { $descriptionMatch.Groups[1].Value.Trim() } else { '' }
    if ($name -cnotmatch '^[a-z0-9]+(-[a-z0-9]+)*$' -or $name.Length -gt 64) {
        $errors.Add("Invalid name: $path")
    }
    if ($name -cne $directory.Name) {
        $errors.Add("Directory/name mismatch: $path")
    }
    if ($description.Length -lt 1 -or $description.Length -gt 1024) {
        $errors.Add("Invalid description length: $path")
    }
    if ($seen.ContainsKey($name)) { $errors.Add("Duplicate name: $name") }
    $seen[$name] = $true
    if ($content.Substring($head.Length).Trim().Length -lt 100) {
        $errors.Add("Instructions appear incomplete: $path")
    }
}
if ($directories.Count -eq 0) { $errors.Add('No skills found.') }
if ($errors.Count -gt 0) {
    $errors | ForEach-Object { Write-Error $_ }
    exit 1
}
Write-Host "PASS: $($directories.Count) skills passed structural checks."
