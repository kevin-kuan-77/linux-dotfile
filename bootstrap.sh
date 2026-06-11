#!/usr/bin/env sh
# Bootstrap your config on a fresh machine.
#
# Usage:
#   sh -c "$(curl -fsSL https://raw.githubusercontent.com/<you>/<repo>/main/bootstrap.sh)"
# or, after cloning the script down:
#   DOTFILES_REMOTE=git@github.com:<you>/<repo>.git ./bootstrap.sh

set -eu

# Where the bare repository lives. Override with DOTFILES_DIR if you like.
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.cfg}"
# Your config remote. Edit this default or pass DOTFILES_REMOTE=... in the env.
DOTFILES_REMOTE="${DOTFILES_REMOTE:-git@github.com:CHANGE_ME/config.git}"
BACKUP_DIR="$HOME/.cfg-backup"

# A throwaway function so we don't depend on the shell alias existing yet.
config() {
    git --git-dir="$DOTFILES_DIR" --work-tree="$HOME" "$@"
}

echo ">> Cloning $DOTFILES_REMOTE (bare) into $DOTFILES_DIR"
git clone --bare "$DOTFILES_REMOTE" "$DOTFILES_DIR"

echo ">> Checking out files into \$HOME"
if ! config checkout 2>/dev/null; then
    echo ">> Existing files would be overwritten. Backing them up to $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
    config checkout 2>&1 \
        | grep -E "^\s+\." \
        | awk '{print $1}' \
        | while read -r f; do
            mkdir -p "$BACKUP_DIR/$(dirname "$f")"
            mv "$HOME/$f" "$BACKUP_DIR/$f"
        done
    config checkout
fi

echo ">> Hiding untracked files so 'config status' isn't noisy"
config config --local status.showUntrackedFiles no

echo ">> Done. Open a new shell (or 'source ~/.bashrc') and use the 'config' command."
