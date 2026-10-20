#requires -Version 5.1
<#
.SYNOPSIS
  Self-test for validate-skills.ps1 using synthetic fixture skills.
.DESCRIPTION
  Builds a temporary skills root with one valid CRLF skill, one valid LF skill and
  several deliberately broken skills, then asserts that validate-skills.ps1 reports
  exactly the expected problems and exit codes. Nothing outside the system temp
  folder is touched; the temporary folder is removed at the end.
.EXAMPLE
  ./scripts/test-validate-skills.ps1
#>
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$validator = Join-Path $PSScriptRoot 'validate-skills.ps1'
if (-not (Test-Path -LiteralPath $validator -PathType Leaf)) { throw "Missing validator: $validator" }

$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('MyWorkSkills-validator-test-' + [guid]::NewGuid().ToString('N'))
$failures = New-Object System.Collections.Generic.List[string]

function New-FixtureSkill {
    param(
        [string]$Root,
        [string]$Folder,
        [string]$Frontmatter,
        [string]$Body,
        [switch]$Crlf,
        [switch]$Utf8Bom
    )
    $directory = Join-Path $Root $Folder
    New-Item -ItemType Directory -Path $directory -Force | Out-Null
    $text = $Frontmatter + $Body
    if ($Crlf) { $text = $text -replace "`r?`n", "`r`n" }
    $path = Join-Path $directory 'SKILL.md'
    if ($Utf8Bom) {
        [System.IO.File]::WriteAllText($path, $text, (New-Object System.Text.UTF8Encoding($true)))
    }
    else {
        [System.IO.File]::WriteAllText($path, $text, (New-Object System.Text.UTF8Encoding($false)))
    }
}

function Invoke-Validator {
    param([string]$Root)
    $output = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $validator -SkillsRoot $Root 2>&1 | Out-String
    return [pscustomobject]@{ ExitCode = $LASTEXITCODE; Output = $output }
}

function Assert-Contains {
    param([string]$Name, [string]$Haystack, [string]$Needle)
    if ($Haystack -notlike "*$Needle*") { $failures.Add("$Name : expected output to contain '$Needle'") }
}

try {
    $goodBody = "`n## Use`n`nFollow the documented steps, record evidence, and never report unverified results as passed.`n"

    # Scenario 1: only valid skills (LF and CRLF) must exit 0.
    $validRoot = Join-Path $tempRoot 'valid'
    New-FixtureSkill -Root $validRoot -Folder 'lf-skill' -Crlf:$false `
        -Frontmatter "---`nname: lf-skill`ndescription: Use for LF line-ending validation tests.`n---`n" -Body $goodBody
    New-FixtureSkill -Root $validRoot -Folder 'crlf-skill' -Crlf `
        -Frontmatter "---`nname: crlf-skill`ndescription: Use for CRLF line-ending validation tests.`n---`n" -Body $goodBody
    $valid = Invoke-Validator -Root $validRoot
    if ($valid.ExitCode -ne 0) { $failures.Add("valid fixtures: expected exit 0, got $($valid.ExitCode). Output: $($valid.Output)") }
    Assert-Contains 'valid fixtures' $valid.Output 'PASS: 2 skills'

    # Scenario 2: every broken fixture must be reported, all in one run.
    $brokenRoot = Join-Path $tempRoot 'broken'
    New-FixtureSkill -Root $brokenRoot -Folder 'good-skill' `
        -Frontmatter "---`nname: good-skill`ndescription: Use as the healthy control case.`n---`n" -Body $goodBody
    New-FixtureSkill -Root $brokenRoot -Folder 'name-mismatch' `
        -Frontmatter "---`nname: other-name`ndescription: Use for name mismatch detection.`n---`n" -Body $goodBody
    New-FixtureSkill -Root $brokenRoot -Folder 'colon-desc' `
        -Frontmatter "---`nname: colon-desc`ndescription: Use when: YAML colon handling is tested.`n---`n" -Body $goodBody
    New-FixtureSkill -Root $brokenRoot -Folder 'no-frontmatter' `
        -Frontmatter "# Missing frontmatter`n" -Body $goodBody
    New-FixtureSkill -Root $brokenRoot -Folder 'short-body' `
        -Frontmatter "---`nname: short-body`ndescription: Use for short body detection.`n---`n" -Body "`nTODO`n"
    New-FixtureSkill -Root $brokenRoot -Folder 'Upper-Name' `
        -Frontmatter "---`nname: Upper-Name`ndescription: Use for kebab-case detection.`n---`n" -Body $goodBody
    New-FixtureSkill -Root $brokenRoot -Folder 'long-desc' `
        -Frontmatter ("---`nname: long-desc`ndescription: {0}`n---`n" -f ('x' * 1100)) -Body $goodBody
    New-FixtureSkill -Root $brokenRoot -Folder 'bom-skill' -Utf8Bom `
        -Frontmatter "---`nname: bom-skill`ndescription: Use for BOM warning detection.`n---`n" -Body $goodBody

    $broken = Invoke-Validator -Root $brokenRoot
    if ($broken.ExitCode -ne 1) { $failures.Add("broken fixtures: expected exit 1, got $($broken.ExitCode)") }
    Assert-Contains 'broken fixtures' $broken.Output "name 'other-name' does not match folder name"
    Assert-Contains 'broken fixtures' $broken.Output "description contains ': ' and is not quoted"
    Assert-Contains 'broken fixtures' $broken.Output "does not start with a '---' frontmatter block"
    Assert-Contains 'broken fixtures' $broken.Output 'instruction body is shorter than 100 characters'
    Assert-Contains 'broken fixtures' $broken.Output 'is not lowercase kebab-case'
    Assert-Contains 'broken fixtures' $broken.Output 'description is longer than 1024 characters'
    Assert-Contains 'broken fixtures' $broken.Output 'starts with a UTF-8 BOM'
    Assert-Contains 'broken fixtures' $broken.Output 'FAIL: 8 skill folder(s) checked'
    if ($broken.Output -match 'good-skill') { $failures.Add('broken fixtures: healthy control skill must not be reported') }

    # Scenario 3: missing name/description must both be reported.
    $missingRoot = Join-Path $tempRoot 'missing'
    New-FixtureSkill -Root $missingRoot -Folder 'empty-meta' -Frontmatter "---`ntitle: not-a-skill-key`n---`n" -Body $goodBody
    $missing = Invoke-Validator -Root $missingRoot
    if ($missing.ExitCode -ne 1) { $failures.Add("missing metadata: expected exit 1, got $($missing.ExitCode)") }
    Assert-Contains 'missing metadata' $missing.Output "missing 'name'"
    Assert-Contains 'missing metadata' $missing.Output "missing 'description'"
    Assert-Contains 'missing metadata' $missing.Output "unknown frontmatter key 'title'"
}
finally {
    if (Test-Path -LiteralPath $tempRoot) { Remove-Item -LiteralPath $tempRoot -Recurse -Force }
}

if ($failures.Count -gt 0) {
    foreach ($failure in $failures) { Write-Host "FAIL  $failure" }
    Write-Host "FAIL: $($failures.Count) assertion(s) failed."
    exit 1
}

Write-Host 'PASS: validator self-test (valid LF/CRLF accepted; 6 structural defects + 1 BOM warning detected in a single run).'
