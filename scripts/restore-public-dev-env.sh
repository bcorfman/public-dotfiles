#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
apt_manifest="$repo_root/manifests/apt-packages.txt"
brew_manifest="$repo_root/manifests/Brewfile"
brew_prefix="/home/linuxbrew/.linuxbrew"

if command -v sudo >/dev/null 2>&1; then
    sudo apt-get update
    sudo xargs -a "$apt_manifest" apt-get install -y
else
    echo "sudo is required for apt restore" >&2
    exit 1
fi

if ! command -v brew >/dev/null 2>&1; then
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

if [ -x "$brew_prefix/bin/brew" ]; then
    eval "$("$brew_prefix/bin/brew" shellenv)"
else
    echo "Homebrew install completed but brew was not found at $brew_prefix/bin/brew" >&2
    exit 1
fi

brew bundle --file="$brew_manifest"

cat <<'EOF'

Base tooling restore finished.

Next steps:
1. Open a new shell if brew-installed tools are not yet on PATH.
2. Run `chezmoi init <public-dotfiles-repo-url>` and `chezmoi apply`.
3. Restore private credentials and local-only files.
4. Run `gh auth status` and re-authenticate if needed.
EOF
