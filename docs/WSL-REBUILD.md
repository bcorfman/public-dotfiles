# WSL Rebuild Runbook

This runbook describes a safe high-level rebuild flow for a WSL Ubuntu
development environment using:

- a public chezmoi source repo for non-secret configuration
- a separate private backup for secrets and identity material
- a separate repo-restore workflow for local development repositories

It is intentionally sanitized for publication. It does not include local
machine paths, usernames, secret values, or private repository inventory.

## Recommended Base Distro

Use `Ubuntu-24.04` LTS for a rebuild unless there is a specific compatibility
reason to stay on an older release.

## 1. Remove The Old WSL Distro

From Windows PowerShell:

```powershell
wsl --shutdown
wsl -l -v
wsl --unregister <OldDistroName>
```

If you created manual `.vhdx` backups or custom imported distros, delete those
 files separately after confirming they are no longer needed.

## 2. Install A Fresh Ubuntu Distro

From Windows PowerShell:

```powershell
wsl --install -d Ubuntu-24.04
```

If needed:

```powershell
wsl --list --online
```

Launch the new distro once and create the Linux user.

## 3. Install Basic Packages

Inside Ubuntu:

```bash
sudo apt update
sudo apt install -y git curl unzip rsync build-essential
```

Install any additional tooling required by your own repos, such as Git LFS.

## 4. Restore Private Material

Restore secrets and identity material from your private backup location before
applying public dotfiles.

Examples of private material that should stay out of the public repo:

- SSH keys
- GPG secret keys
- GitHub CLI auth material
- application credentials
- environment files containing secrets

After restoring sensitive files, fix permissions as needed.

## 5. Ensure Git Credential Integration Exists

If your WSL Git workflow depends on Windows Git Credential Manager, make sure:

- Windows Git is installed
- the credential helper binary exists on the Windows side
- your local chezmoi machine data restores the correct helper path

## 6. Install Chezmoi

Inside Ubuntu:

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin
export PATH="$HOME/.local/bin:$PATH"
chezmoi --version
```

Persist the path in your shell startup if needed.

## 7. Recreate Local Machine Data

Create local chezmoi data outside the public repo for machine-specific values,
such as:

- identity values
- browser command
- credential-helper path
- socket paths
- tool-specific local binary paths

Do not commit this machine data to a public repo.

## 8. Restore Public Dotfiles

Inside Ubuntu:

```bash
chezmoi init <public-dotfiles-repo-url>
chezmoi apply
```

## 9. Verify Git Authentication

Run a non-destructive Git remote command against a repository you can access:

```bash
git config --global --get credential.helper
git config --global --get credential.credentialStore
git ls-remote <repo-url>
```

If this succeeds without prompting for new credentials, Git auth is configured
correctly.

## 10. Restore Development Repositories

Run your repo-restore process from a separately stored manifest or script.

This should restore:

- remote URLs
- intended checked-out branches
- preserved in-process branches where needed

## 11. Restore Repo-Local Secret Files

Some repos may depend on local-only files such as `.env` or tool credentials.
Restore those from private backup after cloning the repos.

## 12. Final Checks

Examples:

```bash
gh auth status
gpg --list-secret-keys
git -C ~/dev/<repo> status
git -C ~/dev/<repo> branch --show-current
git -C ~/dev/<repo> remote -v
```

## Failure Notes

If `chezmoi apply` fails:

- check local chezmoi machine data

If Git auth fails:

- verify the credential helper path
- verify the Windows-side credential store still exists

If CLI auth fails:

- re-authenticate with the relevant CLI tool

If repo-local secrets are missing:

- restore them from your private backup set
