param(
    [Parameter(Mandatory = $true)]
    [string] $TaskPath,

    [ValidateSet("advise", "execute", "review")]
    [string] $Mode = "execute",

    [string] $Workspace = (Get-Location).Path,

    [string] $ConfigPath = (Join-Path $HOME ".codex\claude-executor\config.json"),

    [string] $RunName
)

$ErrorActionPreference = "Stop"

function Read-Config($path) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Claude executor config does not exist. Run Set-ClaudeExecutor.ps1 first."
    }
    Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
}

function Resolve-ExistingFile($path) {
    $resolved = Resolve-Path -LiteralPath $path -ErrorAction Stop
    $item = Get-Item -LiteralPath $resolved.Path
    if ($item.PSIsContainer) {
        throw "Expected a file, got directory: $path"
    }
    $item.FullName
}

function Resolve-ExistingDirectory($path) {
    $resolved = Resolve-Path -LiteralPath $path -ErrorAction Stop
    $item = Get-Item -LiteralPath $resolved.Path
    if (-not $item.PSIsContainer) {
        throw "Expected a directory, got file: $path"
    }
    $item.FullName
}

$config = Read-Config $ConfigPath

if (-not [bool]$config.enabled) {
    throw "Claude executor is disabled. Enable it with Set-ClaudeExecutor.ps1 -Enabled `$true."
}

if ($config.forbiddenPermissionModes -contains $config.permissionMode) {
    throw "Permission mode '$($config.permissionMode)' is forbidden by config."
}

$claudeCommand = Get-Command claude -ErrorAction Stop
$workspaceFull = Resolve-ExistingDirectory $Workspace
$taskFull = Resolve-ExistingFile $TaskPath
$taskDir = Split-Path -Parent $taskFull
$resultPath = Join-Path $taskDir ([string]$config.resultFileName)
$advicePath = Join-Path $taskDir ([string]$config.adviceFileName)
$reviewPath = Join-Path $taskDir ([string]$config.reviewFileName)

switch ($Mode) {
    "advise" {
        $targetOutputPath = $advicePath
        $modeRules = @"
Mode: independent adviser.

Rules:
- Think independently about the task plan, implementation risks, missing tests, and safer alternatives.
- Read relevant files if needed.
- Do not edit, create, delete, move, format, or install anything.
- Write this advice file:
$targetOutputPath

CLAUDE_ADVICE.md must contain:
1. Independent understanding of the goal
2. Main risks or ambiguities
3. Suggested implementation strategy
4. Suggested validation commands
5. Questions or blockers, if any
"@
    }
    "execute" {
        $targetOutputPath = $resultPath
        $modeRules = @"
Mode: execution agent.

Rules:
- Implement only what TASK.md requests.
- Respect allowed and forbidden files in TASK.md.
- Do not change user/system configuration.
- Do not delete files unless TASK.md explicitly asks for it.
- Do not install dependencies unless TASK.md explicitly asks for it.
- Run only the validation commands requested in TASK.md, plus minimal diagnostics needed to fix failures.
- After finishing, write this result file:
$targetOutputPath

RESULT.md must contain:
1. Summary
2. Files changed
3. Commands run
4. Test results
5. Remaining risks
"@
    }
    "review" {
        $targetOutputPath = $reviewPath
        $modeRules = @"
Mode: independent reviewer.

Rules:
- Review TASK.md, RESULT.md if present, current git diff, and relevant logs/files.
- Do not edit, create, delete, move, format, or install anything except writing this review file:
$targetOutputPath
- Focus on bugs, regressions, missing tests, risky assumptions, and whether success criteria were met.

CLAUDE_REVIEW.md must contain:
1. Verdict
2. Findings ordered by severity
3. Missing validation
4. Suggested next action
"@
    }
}

if (-not $RunName) {
    $RunName = "claude-run-" + (Get-Date -Format "yyyyMMdd-HHmmss")
}

$runDir = Join-Path $taskDir $RunName
New-Item -ItemType Directory -Path $runDir -Force | Out-Null

$stdoutPath = Join-Path $runDir "claude-output.json"
$stderrPath = Join-Path $runDir "claude-error.txt"
$promptPath = Join-Path $runDir "prompt.txt"
$summaryPath = Join-Path $runDir "run-summary.json"

$prompt = @"
You are a delegated Claude Code worker in a Codex-controlled workflow.

Read this task file:
$taskFull

Work in this workspace:
$workspaceFull

$modeRules
"@

Set-Content -LiteralPath $promptPath -Value $prompt -Encoding UTF8

$claudeArgs = @(
    "-p", $prompt,
    "--permission-mode", ([string]$config.permissionMode),
    "--output-format", ([string]$config.outputFormat),
    "--max-budget-usd", ([string]::Format([Globalization.CultureInfo]::InvariantCulture, "{0}", [double]$config.maxBudgetUsd))
)

$allowedTools = @()
if ($Mode -eq "execute") {
    if ($config.allowedTools -and $config.allowedTools.Count -gt 0) {
        $allowedTools = $config.allowedTools | ForEach-Object { [string]$_ }
    }
}
else {
    $allowedTools = @(
        "Read",
        "Bash(git *)",
        "Bash(Get-ChildItem *)",
        "Bash(Get-Content *)",
        "Bash(Select-String *)",
        "Bash(rg *)",
        "Write"
    )
}

if ($allowedTools.Count -gt 0) {
    $claudeArgs += @("--allowedTools", ($allowedTools -join ","))
}

$exitCode = 0
$startedAt = Get-Date
Push-Location $workspaceFull
try {
    $output = & $claudeCommand.Source @claudeArgs 2> $stderrPath
    $exitCode = $LASTEXITCODE
    $output | Set-Content -LiteralPath $stdoutPath -Encoding UTF8
}
finally {
    Pop-Location
}
$endedAt = Get-Date

$targetOutputExists = Test-Path -LiteralPath $targetOutputPath
$resultExists = Test-Path -LiteralPath $resultPath
$adviceExists = Test-Path -LiteralPath $advicePath
$reviewExists = Test-Path -LiteralPath $reviewPath
$summary = [ordered]@{
    startedAt = $startedAt.ToString("o")
    endedAt = $endedAt.ToString("o")
    exitCode = $exitCode
    workspace = $workspaceFull
    mode = $Mode
    taskPath = $taskFull
    targetOutputPath = $targetOutputPath
    targetOutputExists = $targetOutputExists
    resultPath = $resultPath
    resultExists = $resultExists
    advicePath = $advicePath
    adviceExists = $adviceExists
    reviewPath = $reviewPath
    reviewExists = $reviewExists
    stdoutPath = $stdoutPath
    stderrPath = $stderrPath
    promptPath = $promptPath
    permissionMode = [string]$config.permissionMode
    maxBudgetUsd = [double]$config.maxBudgetUsd
}

$summary | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $summaryPath -Encoding UTF8
$summary | ConvertTo-Json -Depth 6

if ($exitCode -ne 0) {
    exit $exitCode
}

if ([bool]$config.requireResultFile -and -not $targetOutputExists) {
    throw "Claude completed but did not create expected output file: $targetOutputPath"
}
