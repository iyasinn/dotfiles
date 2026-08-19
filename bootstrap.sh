#!/usr/bin/env bash
set -e

# Get the directory of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Run from the dotfiles repo, even if this script was started somewhere else.
if [[ "$PWD" != "$SCRIPT_DIR" ]]; then
  echo "==> Switching to $SCRIPT_DIR"
  cd "$SCRIPT_DIR"
fi

# Install Homebrew if missing.
if ! command -v brew >/dev/null 2>&1; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Make Homebrew available in this script.
eval "$(/opt/homebrew/bin/brew shellenv)"

# Install apps/tools from Brewfile.
brew bundle --file Brewfile

# Symlink dotfiles into $HOME.
stow --restow --verbose home

# Install mise tools if any are configured.
mise install || true
