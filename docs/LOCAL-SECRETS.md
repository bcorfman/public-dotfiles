# Local Secrets And Machine Data

This repo is intentionally public. Anything that reveals local filesystem
layout, credential-helper locations, socket paths, usernames, or identity
values should live in local chezmoi data, not in GitHub.

## Local Config File

Keep machine-only values in your local chezmoi config:

`~/.config/chezmoi/chezmoi.toml`

Example:

```toml
[data.identity]
name = "Your Name"
email = "you@example.com"

[data.machine]
browser = "xdg-open"
postgresqlBinDir = "/some/private/path/bin"
gitCredentialHelper = "/some/private/path/to/helper"
gitCredentialStore = "wincredman"
pulseServer = "unix:/some/private/socket"

[encryption]
recipient = "age1..."
```

## What Stays Local

- identity values
- machine-specific paths
- credential-helper paths
- socket paths
- encryption recipients if you do not want them published

## WSL Git Credential Manager Restore

For this setup, the GitHub PAT itself is not stored in WSL. The restored WSL
Git config points at Windows Git Credential Manager, and the actual credential
material stays in Windows Credential Manager.

That means a WSL rebuild is normally seamless if:

- Windows Git is installed
- your local chezmoi machine data restores the helper path
- your Windows profile still contains the saved credential entries

Recommended local machine values:

```toml
[data.machine]
gitCredentialHelper = "/mnt/c/Program Files/Git/mingw64/bin/git-credential-manager.exe"
gitCredentialStore = "wincredman"
```

Recommended post-restore check:

```bash
git config --global --get credential.helper
git ls-remote https://github.com/bcorfman/public-dotfiles.git
```

For browser launching on newer WSL distros, `xdg-open` is the safest default.
If you are on an older Ubuntu release with `wslu` installed and prefer it, you
can still set `browser = "wslview"` in local machine data.

If the helper path is wrong or Windows Git is missing, Git auth from WSL will
fail even though the PAT still exists in Windows Credential Manager.

## Chezmoi Features To Use

- Use `.chezmoi.toml.tmpl` to prompt for initial identity values during
  `chezmoi init`.
- Use local `~/.config/chezmoi/chezmoi.toml` to override machine-only data.
- Use `chezmoi add --encrypt` for files that should exist in source state but
  not in plaintext.
- Use password-manager-backed template functions if you want secrets fetched at
  apply time instead of stored in source state.
