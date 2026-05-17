# CLI Discord Presence

Discord Rich Presence for AI/agent CLIs. Download one binary, add one alias, and your Discord status follows the CLI only while it is running.

Repository: https://github.com/two-tech-dev/CLI-Discord-Presence

## Supported CLIs

- Claude Code (`claude`)
- Codex CLI (`codex`)
- Gemini CLI (`gemini`)
- opencode (`opencode`)
- Custom commands such as `node`, `npm`, or any executable on `PATH`

## Quick install

No Node.js, npm, or repo clone is required.

Linux/macOS:

```sh
curl -fsSL https://raw.githubusercontent.com/two-tech-dev/CLI-Discord-Presence/main/scripts/install.sh | bash
```

Windows PowerShell:

```powershell
iwr https://raw.githubusercontent.com/two-tech-dev/CLI-Discord-Presence/main/scripts/install.ps1 -UseB | iex
```

The installer downloads the latest release binary, installs it locally, asks which CLIs to enable, and writes aliases/functions to your shell profile.

## Manual install

Download the binary for your OS from:

https://github.com/two-tech-dev/CLI-Discord-Presence/releases

Pick one:

- `cli-presence-linux-x64`
- `cli-presence-linux-arm64`
- `cli-presence-macos-x64`
- `cli-presence-macos-arm64`
- `cli-presence-windows-x64.exe`

Then place it somewhere on your `PATH` as `cli-presence` or `cli-presence.exe` and add aliases manually.

## Usage

After installing aliases, just run the CLI normally:

```sh
claude
opencode
codex
```

The wrapper starts Discord Rich Presence, launches the real CLI, then clears the presence when the CLI exits.

## Custom command example

Linux/macOS:

```sh
alias nodejs="PRESENCE_PROFILE=custom PRESENCE_APP_NAME='Node.js' PRESENCE_STATE='Using Node.js' PRESENCE_LARGE_IMAGE=node PRESENCE_BIN=node cli-presence --"
```

PowerShell:

```powershell
function nodejs { $env:PRESENCE_PROFILE='custom'; $env:PRESENCE_APP_NAME='Node.js'; $env:PRESENCE_STATE='Using Node.js'; $env:PRESENCE_LARGE_IMAGE='node'; $env:PRESENCE_BIN='node'; cli-presence -- @args }
```

## Options

Set these environment variables in your alias/function when needed:

- `PRESENCE_PROFILE`: `claude`, `codex`, `gemini`, `opencode`, or `custom`.
- `PRESENCE_BIN`: Override the executable path for the selected CLI.
- `PRESENCE_MODEL`: Override the model shown in Discord.
- `PRESENCE_SHOW_MODEL`: Set to `0` to hide model text. Defaults to enabled.
- `PRESENCE_IDLE_AFTER_MS`: Milliseconds before showing idle. Defaults to `120000`.
- `PRESENCE_LARGE_IMAGE`: Override large asset key.
- `PRESENCE_SMALL_IMAGE`: Override active small asset key.
- `PRESENCE_IDLE_IMAGE`: Override idle small asset key.
- `PRESENCE_APP_NAME`: Override large image hover text.
- `PRESENCE_STATE`: Override active state text.
- `PRESENCE_CLIENT_ID`: Override Discord application ID. Defaults to the project app ID.

Per-CLI binary overrides:

- `CLAUDE_BIN`
- `CODEX_BIN`
- `GEMINI_BIN`
- `OPENCODE_BIN`

Per-CLI model envs detected automatically:

- Claude: `CLAUDE_MODEL`, `ANTHROPIC_MODEL`, `ANTHROPIC_DEFAULT_OPUS_MODEL`, `ANTHROPIC_DEFAULT_SONNET_MODEL`, `ANTHROPIC_DEFAULT_HAIKU_MODEL`
- Codex: `OPENAI_MODEL`, `CODEX_MODEL`
- Gemini: `GEMINI_MODEL`
- opencode: `OPENCODE_MODEL`

`--model` and `-m` are also detected when passed to the wrapped CLI.

## Discord assets

The project Discord application should include these Rich Presence asset keys:

Required:

- `claude`
- `codex`
- `gemini`
- `opencode`
- `terminal`
- `idle`

Recommended for custom commands:

- `node`
- `npm`

Optional future file-type assets:

- `javascript`
- `typescript`
- `python`
- `markdown`
- `json`
- `yaml`
- `shell`
- `git`

## Development

Only contributors need this section.

```sh
npm install
npm link
```

Run from source:

```sh
cli-presence -- --version
```

Build standalone binaries:

```sh
npm run build
```

Publish a GitHub release by pushing a tag:

```sh
git tag v0.1.0
git push origin v0.1.0
```
