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

$selection = Ask-Default "Enter numbers separated by commas, or all" "all"
$showModel = Ask-YesNo "Show model in Discord presence?" $true
$profilePath = Ask-Default "PowerShell profile path" $PROFILE

$selected = if ($selection.Trim().ToLowerInvariant() -eq "all") { "1,2,3,4" } else { $selection }
$lines = @(
  "",
  "# CLI Discord Presence",
  "`$env:Path='$InstallDir;' + `$env:Path",
  "`$env:PRESENCE_SHOW_MODEL='$(if ($showModel) { '1' } else { '0' })'"
)

function Has-Selection($Value) {
  return ("," + $selected + ",") -like "*,$Value,*"
}

if (Has-Selection "1") { $lines += "function claude { & '$BinaryPath' -- @args }" }
if (Has-Selection "2") { $lines += "function codex { `$env:PRESENCE_PROFILE='codex'; & '$BinaryPath' codex -- @args }" }
if (Has-Selection "3") { $lines += "function gemini { `$env:PRESENCE_PROFILE='gemini'; & '$BinaryPath' gemini -- @args }" }
if (Has-Selection "4") { $lines += "function opencode { `$env:PRESENCE_PROFILE='opencode'; & '$BinaryPath' opencode -- @args }" }
if (Has-Selection "5") {
  $alias = Ask-Default "Custom alias name" "nodejs"
  $command = Ask-Default "Command to run" "node"
  $label = Ask-Default "Discord label" $command
  $asset = Ask-Default "Large asset key" "terminal"
  $lines += "function $alias { `$env:PRESENCE_PROFILE='custom'; `$env:PRESENCE_APP_NAME='$label'; `$env:PRESENCE_STATE='Using $label'; `$env:PRESENCE_LARGE_IMAGE='$asset'; `$env:PRESENCE_BIN='$command'; & '$BinaryPath' -- @args }"
}

$snippet = $lines -join [Environment]::NewLine

if (Ask-YesNo "Write aliases to $profilePath?" $true) {
  $profileDir = Split-Path -Parent $profilePath
  if (-not (Test-Path $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir | Out-Null
  }
  Add-Content -Path $profilePath -Value $snippet
  Write-Host "Installed cli-presence to $BinaryPath"
  Write-Host "Restart PowerShell or run: . `$PROFILE"
} else {
  Write-Host $snippet
}
