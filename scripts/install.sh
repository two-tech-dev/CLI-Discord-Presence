#!/usr/bin/env bash
set -euo pipefail

REPO="two-tech-dev/CLI-Discord-Presence"
INSTALL_DIR="${CLI_PRESENCE_INSTALL_DIR:-$HOME/.local/bin}"
BIN_NAME="cli-presence"

OPTIONS=("Claude Code" "Codex CLI" "Gemini CLI" "opencode" "Custom command")
COMMANDS=("claude" "codex" "gemini" "opencode" "")
SELECTED=(0 0 0 0 0)
SELECTION=""

if [ -t 1 ]; then
  BOLD=$'\033[1m'
  DIM=$'\033[2m'
  GREEN=$'\033[32m'
  CYAN=$'\033[36m'
  YELLOW=$'\033[33m'
  RESET=$'\033[0m'
else
  BOLD=''
  DIM=''
  GREEN=''
  CYAN=''
  YELLOW=''
  RESET=''
fi

if [ -r /dev/tty ] && [ -w /dev/tty ]; then
  exec 3<>/dev/tty
  TTY_FD=3
else
  TTY_FD=2
fi

info() { printf "${CYAN}%s${RESET}\n" "$1" >&2; }
success() { printf "${GREEN}%s${RESET}\n" "$1" >&2; }
warn() { printf "${YELLOW}%s${RESET}\n" "$1" >&2; }

printf "${BOLD}CLI Discord Presence installer${RESET}\n\n" >&2

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

info "Downloading $asset..."
if command -v curl >/dev/null 2>&1; then
  curl -fsSL "$url" -o "$INSTALL_DIR/$BIN_NAME"
elif command -v wget >/dev/null 2>&1; then
  wget -q "$url" -O "$INSTALL_DIR/$BIN_NAME"
else
  echo "curl or wget is required." >&2
  exit 1
fi

chmod +x "$INSTALL_DIR/$BIN_NAME"

for i in "${!COMMANDS[@]}"; do
  if [ -n "${COMMANDS[$i]}" ] && command -v "${COMMANDS[$i]}" >/dev/null 2>&1; then
    SELECTED[$i]=1
  fi
done

detect_profile() {
  local shell_name="${SHELL:-}"
  case "$shell_name" in
    *zsh*) echo "$HOME/.zshrc" ;;
    *bash*) echo "$HOME/.bashrc" ;;
    *)
      if [ -f "$HOME/.zshrc" ]; then
        echo "$HOME/.zshrc"
      else
        echo "$HOME/.profile"
      fi
      ;;
  esac
}

ask() {
  local prompt="$1"
  local default="$2"
  local answer=""

  printf '%s [%s]: ' "$prompt" "$default" >&$TTY_FD
  read -r answer <&$TTY_FD || answer=""

  if [ -z "$answer" ]; then
    printf '%s' "$default"
  else
    printf '%s' "$answer"
  fi
}

ask_yes() {
  local prompt="$1"
  local default="$2"
  local suffix="y/N"
  local answer=""

  [ "$default" = "y" ] && suffix="Y/n"

  printf '%s [%s]: ' "$prompt" "$suffix" >&$TTY_FD
  read -r answer <&$TTY_FD || answer=""

  answer="$(printf '%s' "$answer" | tr '[:upper:]' '[:lower:]')"
  [ -z "$answer" ] && answer="$default"

  [ "$answer" = "y" ] || [ "$answer" = "yes" ]
}

clear_screen() {
  # 2J = clear screen, 3J = clear scrollback, H = move cursor home
  printf '\033[2J\033[3J\033[H' >&$TTY_FD
}

render_select() {
  local cursor="$1"

  clear_screen

  printf "${BOLD}Select CLIs to enable${RESET}\n" >&$TTY_FD
  printf "${DIM}Detected CLIs are preselected. Use ↑/↓, Space to toggle, Enter to continue.${RESET}\n\n" >&$TTY_FD

  for i in "${!OPTIONS[@]}"; do
    local pointer=" "
    local marker=" "
    local status=""

    [ "$i" -eq "$cursor" ] && pointer="›"
    [ "${SELECTED[$i]}" -eq 1 ] && marker="x"

    if [ -n "${COMMANDS[$i]}" ] && command -v "${COMMANDS[$i]}" >/dev/null 2>&1; then
      status=" ${GREEN}(detected)${RESET}"
    elif [ -n "${COMMANDS[$i]}" ]; then
      status=" ${DIM}(not found)${RESET}"
    fi

    printf "  ${CYAN}%s${RESET} [%s] %s%s\n" "$pointer" "$marker" "${OPTIONS[$i]}" "$status" >&$TTY_FD
  done
}

multi_select() {
  if [ "$TTY_FD" != "3" ]; then
    local defaults=""

    for i in "${!SELECTED[@]}"; do
      if [ "${SELECTED[$i]}" -eq 1 ]; then
        defaults="$defaults,$((i + 1))"
      fi
    done

    SELECTION="${defaults#,}"
    return
  fi

  local cursor=0
  local key=""
  local old_stty=""

  old_stty="$(stty -g <&$TTY_FD)"

  cleanup_tty() {
    stty "$old_stty" <&$TTY_FD 2>/dev/null || true
    printf '\033[?25h' >&$TTY_FD
  }

  trap cleanup_tty EXIT INT TERM

  stty -echo -icanon time 0 min 1 <&$TTY_FD
  printf '\033[?25l' >&$TTY_FD

  while true; do
    render_select "$cursor"

    IFS= read -rsn1 key <&$TTY_FD || key=""

    case "$key" in
      "")
        break
        ;;

      " ")
        if [ "${SELECTED[$cursor]}" -eq 1 ]; then
          SELECTED[$cursor]=0
        else
          SELECTED[$cursor]=1
        fi
        ;;

      $'\033')
        IFS= read -rsn2 key <&$TTY_FD || key=""

        case "$key" in
          "[A") cursor=$((cursor - 1)) ;;
          "[B") cursor=$((cursor + 1)) ;;
        esac
        ;;
    esac

    [ "$cursor" -lt 0 ] && cursor=$((${#OPTIONS[@]} - 1))
    [ "$cursor" -ge "${#OPTIONS[@]}" ] && cursor=0
  done

  cleanup_tty
  trap - EXIT INT TERM
  clear_screen

  local selected=""

  for i in "${!SELECTED[@]}"; do
    if [ "${SELECTED[$i]}" -eq 1 ]; then
      selected="$selected,$((i + 1))"
    fi
  done

  SELECTION="${selected#,}"
}

profile="$(ask 'Shell profile path' "$(detect_profile)")"

multi_select
selection="$SELECTION"

show_model="1"
if ! ask_yes 'Show model in Discord presence?' 'y'; then
  show_model="0"
fi

snippet="
# CLI Discord Presence
export PATH=\"$INSTALL_DIR:\$PATH\"
export PRESENCE_SHOW_MODEL=$show_model
"

add_function() {
  snippet="$snippet
unalias $1 2>/dev/null || true
$1() { $2 \"\$@\"; }"
}

case ",$selection," in
  *,1,*) add_function claude 'PRESENCE_PROFILE=claude cli-presence --' ;;
esac

case ",$selection," in
  *,2,*) add_function codex 'PRESENCE_PROFILE=codex cli-presence codex --' ;;
esac

case ",$selection," in
  *,3,*) add_function gemini 'PRESENCE_PROFILE=gemini cli-presence gemini --' ;;
esac

case ",$selection," in
  *,4,*) add_function opencode 'PRESENCE_PROFILE=opencode cli-presence opencode --' ;;
esac

case ",$selection," in
  *,5,*)
    alias_name="$(ask 'Custom function name' 'nodejs')"
    command_name="$(ask 'Command to run' 'node')"
    label="$(ask 'Discord label' "$command_name")"
    large_asset="$(ask 'Large asset key' 'terminal')"

    add_function "$alias_name" "PRESENCE_PROFILE=custom PRESENCE_APP_NAME='$label' PRESENCE_STATE='Using $label' PRESENCE_LARGE_IMAGE='$large_asset' PRESENCE_BIN='$command_name' cli-presence --"
    ;;
esac

if ask_yes "Write functions to $profile?" 'y'; then
  printf '%s\n' "$snippet" >> "$profile"
  success "Installed cli-presence to $INSTALL_DIR/$BIN_NAME"
  info "Restart your shell or run: source $profile"
else
  warn "Add this to your shell profile manually:"
  echo "$snippet"
fi
