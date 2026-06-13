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
browser = "wslview"
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

## Chezmoi Features To Use

- Use `.chezmoi.toml.tmpl` to prompt for initial identity values during
  `chezmoi init`.
- Use local `~/.config/chezmoi/chezmoi.toml` to override machine-only data.
- Use `chezmoi add --encrypt` for files that should exist in source state but
  not in plaintext.
- Use password-manager-backed template functions if you want secrets fetched at
  apply time instead of stored in source state.
