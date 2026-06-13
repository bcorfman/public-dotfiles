# Validation

To validate this public source state locally after installing `chezmoi`:

```bash
../scripts/test-public-dotfiles-with-chezmoi.sh
```

If `chezmoi` was installed with Homebrew and is not on `PATH`, load Homebrew's shell
environment first using your local Homebrew prefix:

```bash
eval "$("$(command -v brew)" shellenv)"
```

What this test does:

- generates a config from `.chezmoi.toml.tmpl`
- applies the source state to a temporary home directory
- verifies key rendered files exist

This checks the chezmoi source state itself, independent of your live home directory.

The source repo is expected to be directly apply-able, not wrapped in an extra
`chezmoi/` staging directory.
