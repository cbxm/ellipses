set -g fish_greeting

# Editor
set -gx VISUAL nvim
set -gx EDITOR nvim

# Aliases
alias ccyo="claude --allow-dangerously-skip-permissions"
alias fishsrc="source ~/.config/fish/config.fish"
alias hn="hackernews_tui"

# Git
alias gs="git status"
alias gp="git push"
alias gl="git pull"
alias gpr="git pull --rebase"
alias gf="git fetch"
alias ga="git add -A"
alias gc="git commit -m"
alias gd="git diff"
alias gco="git checkout"
alias gb="git branch"
alias glog="git log --oneline"

# apt
alias sai="sudo apt install"
alias sar="sudo apt remove"
alias sau="sudo apt update"
alias sug="sudo apt upgrade"
alias sauu="sudo apt update && sudo apt upgrade"
alias alu="apt list --upgradeable"

# Fly.io (multi-app)
alias flp="fly logs -a cassie-prod"
alias fls="fly logs -a cassie-staging"
alias fssp="fly ssh console -a cassie-prod"
alias fsss="fly ssh console -a cassie-staging"

# General
alias l="ls -la"
alias v="vim"
alias lg="lazygit"

# Cargo (Rust)
fish_add_path $HOME/.cargo/bin

# flyctl
set -gx FLYCTL_INSTALL "$HOME/.fly"
fish_add_path $FLYCTL_INSTALL/bin

# === THEME ===
# ANSI colour names only, never hex, so highlighting uses whichever Ghostty theme is
# active and follows a desktop dark/light flip. See docs.md.
# Syntax highlighting
set -g fish_color_normal normal
set -g fish_color_command blue
set -g fish_color_keyword magenta
set -g fish_color_quote green
set -g fish_color_redirection yellow
set -g fish_color_end yellow
set -g fish_color_error red
set -g fish_color_param normal
set -g fish_color_comment brblack
set -g fish_color_selection --reverse
set -g fish_color_search_match --reverse
set -g fish_color_operator yellow
set -g fish_color_escape cyan
set -g fish_color_autosuggestion brblack
set -g fish_color_valid_path --underline

# Pager colors
set -g fish_pager_color_progress brblack
set -g fish_pager_color_prefix blue
set -g fish_pager_color_completion normal
set -g fish_pager_color_description brblack
set -g fish_pager_color_selected_background --reverse

if test -x /home/linuxbrew/.linuxbrew/bin/brew
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
end

# fnm (Node version manager) - auto-switches on .nvmrc
command -q fnm; and fnm env --use-on-cd --shell fish | source

# Starship prompt
command -q starship; and starship init fish | source

# Zoxide (smarter cd)
command -q zoxide; and zoxide init fish | source

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH
