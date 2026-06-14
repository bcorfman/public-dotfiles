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

## 4. Clone The Public Dotfiles Repo

Clone the public repo somewhere convenient so you can use its bootstrap script:

```bash
git clone https://github.com/bcorfman/public-dotfiles.git ~/src/public-dotfiles
```

## 5. Restore Base Tooling

Run the scripted base-tool restore from that checkout:

```bash
~/src/public-dotfiles/scripts/restore-public-dev-env.sh
```

This installs the curated `apt` packages, installs Homebrew if needed, and runs
`brew bundle` for the canonical Brewfile. Tools such as `gh`, `uv`, `pyenv`,
Node, Rust, and `starship` should come from that script rather than ad hoc
manual installs.

The curated `apt` manifest in this repo has been adjusted for Ubuntu 26.04
`resolute`, where older package names like `acpi-support`, `ghostscript-x`,
and `wslu` are no longer available.

If `sudo` prompts for your password during the `apt` phase, enter it and let
the script continue.

## 6. Restore Private Material

Restore secrets and identity material from your private backup location before
applying public dotfiles.

Examples of private material that should stay out of the public repo:

- SSH keys
- GPG secret keys
- GitHub CLI auth material
- application credentials
- environment files containing secrets

After restoring sensitive files, fix permissions as needed.

## 7. Ensure Git Credential Integration Exists

If your WSL Git workflow depends on Windows Git Credential Manager, make sure:

- Windows Git is installed
- the credential helper binary exists on the Windows side
- your local chezmoi machine data restores the correct helper path

## 8. Install Chezmoi

Inside Ubuntu:

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin
export PATH="$HOME/.local/bin:$PATH"
chezmoi --version
```

Persist the path in your shell startup if needed.

## 9. Recreate Local Machine Data

Create local chezmoi data outside the public repo for machine-specific values,
such as:

- identity values
- browser command
- credential-helper path
- socket paths
- tool-specific local binary paths

Do not commit this machine data to a public repo.

## 10. Restore Public Dotfiles

Inside Ubuntu:

```bash
chezmoi init <public-dotfiles-repo-url>
chezmoi apply
```

On first apply, chezmoi may prompt for identity values with text like:

- `Full name for git and cookiecutter?`
- `Email address for git and cookiecutter?`

These prompts are for local configuration data used to populate files such as
`~/.gitconfig` and `~/.cookiecutterrc`. They are not GitHub authentication
prompts.

## 11. Configure Git Authentication In WSL

If WSL is using HTTPS remotes and does not already have a working credential
helper, configure a simple local credential store before restoring private
repositories:

```bash
git config --global credential.helper store
git config --global credential.https://github.com.username <github-username>
```

Then verify Git access against a repository you can read:

```bash
git ls-remote <repo-url>
```

If prompted by GitHub over HTTPS:

- enter your GitHub username as the username
- enter a GitHub Personal Access Token as the password

GitHub account passwords do not work for Git over HTTPS. After the first
successful authentication, the stored credential should be reused for later
repository clones and fetches.

## 12. Restore Development Repositories

Run your repo-restore process from a separately stored manifest or script.

Example:

```bash
bash /path/to/repo-restore/scripts/restore-dev-repos.sh ~/dev
```

This should restore:

- remote URLs
- intended checked-out branches
- preserved in-process branches where needed

If your restore script prints the current repository name before each restore,
that output is useful for diagnosing auth problems. Repeated credential prompts
while the script stays on the same repository usually mean authentication is
failing for that repository. Prompts followed by the next repository name
usually mean the restore is progressing normally across multiple private repos.

## 13. Verify GitHub CLI Authentication

The base-tool restore script installs `gh` through the Brewfile. If GitHub CLI
auth was restored from backup, verify it:

```bash
gh auth status
```

If `gh auth status` fails, authenticate interactively:

```bash
gh auth login
```

## 14. Restore Repo-Local Secret Files

Some repos may depend on local-only files such as `.env` or tool credentials.
Restore those from private backup after cloning the repos.

## 15. Final Checks

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

- verify the configured credential helper
- verify the stored credential is valid for GitHub
- verify the Personal Access Token has the scopes needed for the target repos
- retry `git ls-remote <repo-url>` directly before re-running the full restore

If CLI auth fails:

- verify `gh` is installed and on `PATH`
- re-authenticate with the relevant CLI tool

If repo-local secrets are missing:

- restore them from your private backup set
