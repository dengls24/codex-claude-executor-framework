param(
    [Nullable[bool]] $Enabled,
    [switch] $Status,
    [string] $PermissionMode,
    [double] $MaxBudgetUsd = -1
)

$ErrorActionPreference = "Stop"

$configDir = Join-Path $HOME ".codex\claude-executor"
$configPath = Join-Path $configDir "config.json"

function New-DefaultConfig {
    [ordered]@{
        enabled = $false
        permissionMode = "auto"
        maxBudgetUsd = 1.0
        outputFormat = "json"
        requireResultFile = $true
        resultFileName = "RESULT.md"
        adviceFileName = "CLAUDE_ADVICE.md"
        reviewFileName = "CLAUDE_REVIEW.md"
        forbiddenPermissionModes = @("bypassPermissions")
        allowedTools = @(
            "Read",
            "Edit",
            "Write",
            "Bash(git *)",
            "Bash(python *)",
            "Bash(pytest *)",
            "Bash(npm test *)",
            "Bash(npm run *)"
        )
    }
}

function Read-Config {
    if (-not (Test-Path -LiteralPath $configDir)) {
        New-Item -ItemType Directory -Path $configDir | Out-Null
    }
    if (-not (Test-Path -LiteralPath $configPath)) {
        New-DefaultConfig | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $configPath -Encoding UTF8
    }
    Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
}

function Save-Config($config) {
    $config | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $configPath -Encoding UTF8
}

$config = Read-Config

if ($PSBoundParameters.ContainsKey("Enabled")) {
    $config.enabled = [bool]$Enabled
}

if ($PermissionMode) {
    $validPermissionModes = @("default", "auto", "acceptEdits", "dontAsk", "plan")
    if ($validPermissionModes -notcontains $PermissionMode) {
        throw "Invalid PermissionMode '$PermissionMode'. Valid values: $($validPermissionModes -join ', ')"
    }
    $config.permissionMode = $PermissionMode
}

if ($MaxBudgetUsd -ge 0) {
    $config.maxBudgetUsd = $MaxBudgetUsd
}

if ($PSBoundParameters.ContainsKey("Enabled") -or $PermissionMode -or $MaxBudgetUsd -ge 0) {
    Save-Config $config
}

$safe = [ordered]@{
    configPath = $configPath
    enabled = [bool]$config.enabled
    permissionMode = [string]$config.permissionMode
    maxBudgetUsd = [double]$config.maxBudgetUsd
    outputFormat = [string]$config.outputFormat
    resultFileName = [string]$config.resultFileName
    adviceFileName = [string]$config.adviceFileName
    reviewFileName = [string]$config.reviewFileName
}

$safe | ConvertTo-Json -Depth 4
