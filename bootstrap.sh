#!/usr/bin/env bash
set -e

GREEN="\033[0;32m"
BLUE="\033[0;34m"
YELLOW="\033[1;33m"
RESET="\033[0m"

section() {
  echo
  echo -e "${BLUE}------------------------------------------------------------${RESET}"
  echo -e "${BLUE}==> $1${RESET}"
  echo -e "${BLUE}------------------------------------------------------------${RESET}"
}

done_msg() {
  echo -e "${GREEN}✅ $1${RESET}"
}

warn_msg() {
  echo -e "${YELLOW}⚠️  $1${RESET}"
}

section "Starting dotfiles bootstrap"

section "Finding dotfiles directory"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "Dotfiles directory: $SCRIPT_DIR"
done_msg "Found dotfiles directory"

section "Switching to dotfiles directory"
if [[ "$PWD" != "$SCRIPT_DIR" ]]; then
  cd "$SCRIPT_DIR"
  done_msg "Switched to $SCRIPT_DIR"
else
  done_msg "Already in dotfiles directory"
fi

section "Checking Homebrew"
if ! command -v brew >/dev/null 2>&1; then
  warn_msg "Homebrew missing; installing now"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  done_msg "Homebrew installed"
else
  done_msg "Homebrew already installed"
fi

section "Loading Homebrew environment"
eval "$(/opt/homebrew/bin/brew shellenv)"
done_msg "Homebrew environment loaded"

section "Installing/updating Brewfile packages"
brew bundle --file Brewfile
done_msg "Brewfile packages complete"

section "Stowing dotfiles into $HOME"
stow --restow --verbose --target="$HOME" home
done_msg "Dotfiles stowed"

section "Installing mise tools"
if command -v mise >/dev/null 2>&1; then
  mise install || true
  done_msg "mise install complete"
else
  warn_msg "mise not found; skipping mise install"
fi

section "Bootstrap complete"
done_msg "All done"
