# ellipses

My dotfiles, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## What's here

| Package | What it configures |
|---------|-------------------|
| `fish` | Fish shell (config, functions, conf.d) |
| `ghostty` | Ghostty terminal |
| `tmux` | Tmux (config + custom scripts) |
| `starship` | Starship prompt |
| `bash` | Bash (fallback shell) |
| `nvim` | Neovim |
| `lazygit` | Lazygit TUI |
| `git` | Git config (identity via includes) |
| `kanata` | Keyboard remapping |
| `gh` | GitHub CLI |
| `vscode` | VS Code settings + snippets |
| `claude` | Claude Code config |

## Usage

```bash
# Clone
git clone https://github.com/cbxm/ellipses.git ~/ellipses

# Install stow if needed
sudo apt install stow  # or brew install stow

# Apply all packages
cd ~/ellipses
stow fish ghostty tmux starship bash nvim lazygit git kanata gh vscode claude

# Or apply individually
stow fish
```

## Notes

**Git identity:** The tracked `.gitconfig` uses `[include]` to pull name/email from `~/.gitconfig.local` (not tracked). Create your own:

```bash
cat > ~/.gitconfig.local << 'EOF'
[user]
    name = Your Name
    email = you@example.com
EOF
```

**Secrets:** `gh/hosts.yml` and other sensitive files are gitignored. You'll need to authenticate separately (`gh auth login`, etc).

**Tmux plugins:** Managed by [tpm](https://github.com/tmux-plugins/tpm). After stowing, run `prefix + I` to install.

## Structure

Each directory is a stow package. The internal structure mirrors where files should land relative to `$HOME`:

```
ellipses/
├── fish/
│   └── .config/
│       └── fish/
│           ├── config.fish
│           └── functions/
├── git/
│   ├── .gitconfig
│   └── .config/
│       └── git/
│           └── ignore
└── ...
```

Running `stow fish` from `~/ellipses` creates symlinks like:
- `~/.config/fish/config.fish` → `ellipses/fish/.config/fish/config.fish`

## License

Do whatever you want with this. No warranty.
