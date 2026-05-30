param(
    [string] $CodexSkillsDir = (Join-Path $HOME ".codex\skills")
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$source = Join-Path $repoRoot "skills\claude-executor"
$target = Join-Path $CodexSkillsDir "claude-executor"

if (-not (Test-Path -LiteralPath $source)) {
    throw "Source skill not found: $source"
}

New-Item -ItemType Directory -Path $CodexSkillsDir -Force | Out-Null

if (Test-Path -LiteralPath $target) {
    Remove-Item -LiteralPath $target -Recurse -Force
}

Copy-Item -LiteralPath $source -Destination $target -Recurse -Force

Write-Output "Installed claude-executor skill to: $target"

