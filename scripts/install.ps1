$ErrorActionPreference = "Stop"

$Repo = "two-tech-dev/CLI-Discord-Presence"
$InstallDir = if ($env:CLI_PRESENCE_INSTALL_DIR) { $env:CLI_PRESENCE_INSTALL_DIR } else { Join-Path $env:LOCALAPPDATA "CLI Discord Presence" }
$BinaryPath = Join-Path $InstallDir "cli-presence.exe"
$Url = "https://github.com/$Repo/releases/latest/download/cli-presence-windows-x64.exe"

Write-Host "CLI Discord Presence installer"
Write-Host ""

New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null

Write-Host "Downloading cli-presence-windows-x64.exe..."
Invoke-WebRequest -Uri $Url -OutFile $BinaryPath

if (Get-Command Unblock-File -ErrorAction SilentlyContinue) {
  Unblock-File -Path $BinaryPath
}

function Ask-Default($Question, $Default) {
  $answer = Read-Host "$Question [$Default]"
  if ([string]::IsNullOrWhiteSpace($answer)) { return $Default }
  return $answer.Trim()
}

function Ask-YesNo($Question, $Default) {
  $suffix = if ($Default) { "Y/n" } else { "y/N" }
  $answer = (Read-Host "$Question [$suffix]").Trim().ToLowerInvariant()
  if ([string]::IsNullOrWhiteSpace($answer)) { return $Default }
  return $answer -eq "y" -or $answer -eq "yes"
}

Write-Host ""
Write-Host "Select CLIs to enable:"
Write-Host "  1) Claude Code"
Write-Host "  2) Codex CLI"
Write-Host "  3) Gemini CLI"
Write-Host "  4) opencode"
Write-Host "  5) Custom command"
Write-Host ""

$selection = Ask-Default "Enter numbers separated by commas, or all" "all"
$showModel = Ask-YesNo "Show model in Discord presence?" $true
$profilePath = Ask-Default "PowerShell profile path" $PROFILE

$selected = if ($selection.Trim().ToLowerInvariant() -eq "all") { "1,2,3,4" } else { $selection }

function Has-Selection($Value) {
  return ("," + $selected + ",") -like "*,$Value,*"
}

$showModelValue = if ($showModel) { "1" } else { "0" }

$lines = @(
  "",
  "# CLI Discord Presence",
  "`$env:Path='$InstallDir;' + `$env:Path",
  "`$env:PRESENCE_SHOW_MODEL='$showModelValue'",
  "",
  "function Invoke-CliPresenceWrapped {",
  "  param(",
  "    [string]`$Profile,",
  "    [string]`$Command,",
  "    [string]`$AppName,",
  "    [string]`$State,",
  "    [string]`$LargeImage,",
  "    [string]`$PresenceBin,",
  "    [string[]]`$RemainingArgs",
  "  )",
  "",
  "  `$oldProfile = `$env:PRESENCE_PROFILE",
  "  `$oldAppName = `$env:PRESENCE_APP_NAME",
  "  `$oldState = `$env:PRESENCE_STATE",
  "  `$oldLargeImage = `$env:PRESENCE_LARGE_IMAGE",
  "  `$oldPresenceBin = `$env:PRESENCE_BIN",
  "",
  "  try {",
  "    if (`$Profile) { `$env:PRESENCE_PROFILE = `$Profile }",
  "    if (`$AppName) { `$env:PRESENCE_APP_NAME = `$AppName }",
  "    if (`$State) { `$env:PRESENCE_STATE = `$State }",
  "    if (`$LargeImage) { `$env:PRESENCE_LARGE_IMAGE = `$LargeImage }",
  "    if (`$PresenceBin) { `$env:PRESENCE_BIN = `$PresenceBin }",
  "",
  "    if (`$Command) {",
  "      & '$BinaryPath' `$Command -- @RemainingArgs",
  "    } else {",
  "      & '$BinaryPath' -- @RemainingArgs",
  "    }",
  "  } finally {",
  "    `$env:PRESENCE_PROFILE = `$oldProfile",
  "    `$env:PRESENCE_APP_NAME = `$oldAppName",
  "    `$env:PRESENCE_STATE = `$oldState",
  "    `$env:PRESENCE_LARGE_IMAGE = `$oldLargeImage",
  "    `$env:PRESENCE_BIN = `$oldPresenceBin",
  "  }",
  "}",
  ""
)

if (Has-Selection "1") {
  $lines += "function claude { Invoke-CliPresenceWrapped -Profile 'claude' -RemainingArgs `$args }"
}

if (Has-Selection "2") {
  $lines += "function codex { Invoke-CliPresenceWrapped -Profile 'codex' -Command 'codex' -RemainingArgs `$args }"
}

if (Has-Selection "3") {
  $lines += "function gemini { Invoke-CliPresenceWrapped -Profile 'gemini' -Command 'gemini' -RemainingArgs `$args }"
}

if (Has-Selection "4") {
  $lines += "function opencode { Invoke-CliPresenceWrapped -Profile 'opencode' -Command 'opencode' -RemainingArgs `$args }"
}

if (Has-Selection "5") {
  $alias = Ask-Default "Custom alias name" "nodejs"
  $command = Ask-Default "Command to run" "node"
  $label = Ask-Default "Discord label" $command
  $asset = Ask-Default "Large asset key" "terminal"

  $safeAlias = $alias.Replace("'", "''")
  $safeCommand = $command.Replace("'", "''")
  $safeLabel = $label.Replace("'", "''")
  $safeAsset = $asset.Replace("'", "''")

  $lines += "function $safeAlias { Invoke-CliPresenceWrapped -Profile 'custom' -AppName '$safeLabel' -State 'Using $safeLabel' -LargeImage '$safeAsset' -PresenceBin '$safeCommand' -RemainingArgs `$args }"
}

$snippet = $lines -join [Environment]::NewLine

if (Ask-YesNo "Write aliases to $profilePath?" $true) {
  $profileDir = Split-Path -Parent $profilePath

  if (-not (Test-Path $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
  }

  Add-Content -Path $profilePath -Value $snippet

  Write-Host "Installed cli-presence to $BinaryPath"
  Write-Host "Restart PowerShell or run: . `$PROFILE"
} else {
  Write-Host $snippet
}
