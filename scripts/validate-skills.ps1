#requires -Version 5.1
<#
.SYNOPSIS
  Checks skills/<name>/SKILL.md against basic Agent Skills structural conventions.
.DESCRIPTION
  Checks: a '---' frontmatter block, name (lowercase kebab-case, 1-64 chars, equal to
  its folder name, unique), description (1-1024 chars), a non-trivial instruction body,
  and YAML pitfalls such as an unquoted description containing ': '.
  All problems are collected and reported; the script exits 1 if any error is found.
  This is a structural check only. It does not claim that an Agent client has loaded
  or executed a skill.
.PARAMETER SkillsRoot
  Folder that contains one sub-folder per skill. Defaults to <repo>/skills.
.EXAMPLE
  ./scripts/validate-skills.ps1
#>
[CmdletBinding()]
param(
    [string]$SkillsRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
if (-not $SkillsRoot) { $SkillsRoot = Join-Path $repoRoot 'skills' }
if (-not (Test-Path -LiteralPath $SkillsRoot -PathType Container)) {
    throw "Missing skills directory: $SkillsRoot"
}

$allowedKeys = @('name', 'description', 'license', 'allowed-tools', 'metadata')
$namePattern = '^[a-z0-9]+(-[a-z0-9]+)*$'
$errors = New-Object System.Collections.Generic.List[string]
$warnings = New-Object System.Collections.Generic.List[string]
$seenNames = @{}

function Get-FrontmatterFields {
    param([string[]]$Lines, [int]$Start, [int]$End, [string]$Label)

    $fields = @{}
    for ($i = $Start + 1; $i -lt $End; $i++) {
        $line = $Lines[$i]
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        if ($line -match '^\s*#') { continue }
        if ($line -match '^\s') { continue }   # indented continuation / nested block

        $match = [regex]::Match($line, '^(?<key>[A-Za-z][A-Za-z0-9_-]*)\s*:\s*(?<value>.*)$')
        if (-not $match.Success) {
            $errors.Add("[$Label] invalid frontmatter line $($i + 1): $line")
            continue
        }
        $key = $match.Groups['key'].Value.ToLowerInvariant()
        if ($fields.ContainsKey($key)) { $errors.Add("[$Label] duplicate frontmatter key '$key'") }
        $raw = $match.Groups['value'].Value.Trim()
        $quoted = $raw.Length -ge 2 -and (
            ($raw.StartsWith('"') -and $raw.EndsWith('"')) -or
            ($raw.StartsWith("'") -and $raw.EndsWith("'"))
        )
        $value = if ($quoted) { $raw.Substring(1, $raw.Length - 2) } else { $raw }
        $fields[$key] = [pscustomobject]@{ Value = $value; Quoted = $quoted; Raw = $raw }
        if ($allowedKeys -notcontains $key) { $warnings.Add("[$Label] unknown frontmatter key '$key'") }
    }
    return $fields
}

$directories = @(Get-ChildItem -LiteralPath $SkillsRoot -Directory | Sort-Object Name)
if ($directories.Count -eq 0) { $errors.Add("No skill folders found under $SkillsRoot") }

foreach ($directory in $directories) {
    $label = $directory.Name
    $path = Join-Path $directory.FullName 'SKILL.md'
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        $errors.Add("[$label] missing SKILL.md")
        continue
    }

    $bytes = [System.IO.File]::ReadAllBytes($path)
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        $warnings.Add("[$label] SKILL.md starts with a UTF-8 BOM; some YAML parsers reject it")
    }

    $lines = [System.IO.File]::ReadAllLines($path, [System.Text.Encoding]::UTF8)
    $first = 0
    while ($first -lt $lines.Count -and [string]::IsNullOrWhiteSpace($lines[$first])) { $first++ }
    if ($first -ge $lines.Count -or $lines[$first].Trim() -ne '---') {
        $errors.Add("[$label] SKILL.md does not start with a '---' frontmatter block")
        continue
    }

    $close = -1
    for ($i = $first + 1; $i -lt $lines.Count; $i++) {
        if ($lines[$i].Trim() -eq '---') { $close = $i; break }
    }
    if ($close -lt 0) {
        $errors.Add("[$label] frontmatter block is not closed by '---'")
        continue
    }

    $fields = Get-FrontmatterFields -Lines $lines -Start $first -End $close -Label $label

    $name = if ($fields.ContainsKey('name')) { $fields['name'].Value } else { '' }
    $description = if ($fields.ContainsKey('description')) { $fields['description'].Value } else { '' }

    if (-not $name) {
        $errors.Add("[$label] missing 'name'")
    }
    elseif ($name -cnotmatch $namePattern) {
        $errors.Add("[$label] name '$name' is not lowercase kebab-case (a-z, 0-9, single hyphens)")
    }
    elseif ($name.Length -gt 64) {
        $errors.Add("[$label] name is longer than 64 characters")
    }
    elseif ($name -cne $directory.Name) {
        $errors.Add("[$label] name '$name' does not match folder name '$($directory.Name)'")
    }
    if ($name) {
        if ($seenNames.ContainsKey($name)) { $errors.Add("[$label] duplicate skill name '$name' also used by '$($seenNames[$name])'") }
        else { $seenNames[$name] = $label }
    }

    if (-not $description) {
        $errors.Add("[$label] missing 'description'")
    }
    else {
        if ($description.Length -gt 1024) { $errors.Add("[$label] description is longer than 1024 characters") }
        if (-not $fields['description'].Quoted -and $description -match ':\s') {
            $errors.Add("[$label] description contains ': ' and is not quoted; YAML parsing may fail")
        }
    }

    $bodyLines = if ($close + 1 -lt $lines.Count) { $lines[($close + 1)..($lines.Count - 1)] } else { @() }
    $body = ($bodyLines -join "`n").Trim()
    if ($body.Length -lt 100) { $errors.Add("[$label] instruction body is shorter than 100 characters") }

    $extraFiles = @(Get-ChildItem -LiteralPath $directory.FullName -Force | Where-Object { $_.Name -ne 'SKILL.md' })
    foreach ($extra in $extraFiles) {
        if ($extra.PSIsContainer) { $warnings.Add("[$label] extra folder '$($extra.Name)' (only allowed for skill assets)") }
    }
}

foreach ($warning in $warnings) { Write-Host "WARN  $warning" }
if ($errors.Count -gt 0) {
    foreach ($errorItem in $errors) { Write-Host "ERROR $errorItem" }
    Write-Host "FAIL: $($directories.Count) skill folder(s) checked, $($errors.Count) error(s), $($warnings.Count) warning(s)."
    Write-Host 'Structural check only; loading by an Agent client must be verified separately.'
    exit 1
}

Write-Host "PASS: $($directories.Count) skills passed structural checks ($($warnings.Count) warning(s))."
Write-Host 'Structural check only; loading by an Agent client must be verified separately.'
