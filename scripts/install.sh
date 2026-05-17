#!/usr/bin/env sh
set -eu

REPO="two-tech-dev/CLI-Discord-Presence"
INSTALL_DIR="${CLI_PRESENCE_INSTALL_DIR:-$HOME/.local/bin}"
BIN_NAME="cli-presence"

printf 'CLI Discord Presence installer\n\n'

os="$(uname -s | tr '[:upper:]' '[:lower:]')"
arch="$(uname -m)"

case "$os" in
  linux*) platform="linux" ;;
  darwin*) platform="macos" ;;
  *) echo "Unsupported OS: $os" >&2; exit 1 ;;
esac

case "$arch" in
  x86_64|amd64) cpu="x64" ;;
  arm64|aarch64) cpu="arm64" ;;
  *) echo "Unsupported architecture: $arch" >&2; exit 1 ;;
esac

asset="cli-presence-$platform-$cpu"
url="https://github.com/$REPO/releases/latest/download/$asset"

mkdir -p "$INSTALL_DIR"

echo "Downloading $asset..."
if command -v curl >/dev/null 2>&1; then
  curl -fsSL "$url" -o "$INSTALL_DIR/$BIN_NAME"
elif command -v wget >/dev/null 2>&1; then
  wget -q "$url" -O "$INSTALL_DIR/$BIN_NAME"
else
  echo "curl or wget is required." >&2
  exit 1
fi

chmod +x "$INSTALL_DIR/$BIN_NAME"

detect_profile() {
  shell_name="${SHELL:-}"
  case "$shell_name" in
    *zsh*) echo "$HOME/.zshrc" ;;
    *bash*) echo "$HOME/.bashrc" ;;
    *)
      if [ -f "$HOME/.zshrc" ]; then echo "$HOME/.zshrc"; else echo "$HOME/.profile"; fi
      ;;
  esac
}

ask() {
  prompt="$1"
  default="$2"
  printf '%s [%s]: ' "$prompt" "$default" >&2
  read -r answer || answer=""
  if [ -z "$answer" ]; then printf '%s' "$default"; else printf '%s' "$answer"; fi
}

ask_yes() {
  prompt="$1"
  default="$2"
  suffix="y/N"
  [ "$default" = "y" ] && suffix="Y/n"
  printf '%s [%s]: ' "$prompt" "$suffix" >&2
  read -r answer || answer=""
  answer="$(printf '%s' "$answer" | tr '[:upper:]' '[:lower:]')"
  [ -z "$answer" ] && answer="$default"
  [ "$answer" = "y" ] || [ "$answer" = "yes" ]
}

profile="$(ask 'Shell profile path' "$(detect_profile)")"

cat <<'MENU'

Select CLIs to enable:
  1) Claude Code
  2) Codex CLI
  3) Gemini CLI
  4) opencode
  5) Custom command
MENU
selection="$(ask 'Enter numbers separated by commas, or all' 'all')"
show_model="1"
if ! ask_yes 'Show model in Discord presence?' 'y'; then
  show_model="0"
fi

snippet="
# CLI Discord Presence
export PATH=\"$INSTALL_DIR:\$PATH\"
export PRESENCE_SHOW_MODEL=$show_model
"

add_alias() {
  snippet="$snippet
alias $1='$2'"
}

case ",$selection," in
  *,all,*) selected="1,2,3,4" ;;
  *) selected="$selection" ;;
esac

case ",$selected," in *,1,*) add_alias claude 'cli-presence --' ;; esac
case ",$selected," in *,2,*) add_alias codex 'PRESENCE_PROFILE=codex cli-presence codex --' ;; esac
case ",$selected," in *,3,*) add_alias gemini 'PRESENCE_PROFILE=gemini cli-presence gemini --' ;; esac
case ",$selected," in *,4,*) add_alias opencode 'PRESENCE_PROFILE=opencode cli-presence opencode --' ;; esac
case ",$selected," in
  *,5,*)
    alias_name="$(ask 'Custom alias name' 'nodejs')"
    command_name="$(ask 'Command to run' 'node')"
    label="$(ask 'Discord label' "$command_name")"
    asset="$(ask 'Large asset key' 'terminal')"
    add_alias "$alias_name" "PRESENCE_PROFILE=custom PRESENCE_APP_NAME='$label' PRESENCE_STATE='Using $label' PRESENCE_LARGE_IMAGE='$asset' PRESENCE_BIN='$command_name' cli-presence --"
    ;;
esac

if ask_yes "Write aliases to $profile?" 'y'; then
  printf '%s\n' "$snippet" >> "$profile"
  echo "Installed cli-presence to $INSTALL_DIR/$BIN_NAME"
  echo "Restart your shell or run: source $profile"
else
  echo "$snippet"
fi
