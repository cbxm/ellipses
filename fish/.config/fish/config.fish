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

# Audio - reset sticky default sink/source so wireplumber priorities take over
alias audioauto="wpctl clear-default"

# Cargo (Rust)
fish_add_path $HOME/.cargo/bin

# flyctl
set -gx FLYCTL_INSTALL "$HOME/.fly"
fish_add_path $FLYCTL_INSTALL/bin

# === KANAGAWA DRAGON THEME ===
# Syntax highlighting
set -g fish_color_normal c5c9c5
set -g fish_color_command 8ba4b0
set -g fish_color_keyword 957fb8
set -g fish_color_quote 8a9a7b
set -g fish_color_redirection c4b28a
set -g fish_color_end c4b28a
set -g fish_color_error c4746e
set -g fish_color_param c5c9c5
set -g fish_color_comment 625e5a
set -g fish_color_selection --background=2d4f67
set -g fish_color_search_match --background=2d4f67
set -g fish_color_operator c4b28a
set -g fish_color_escape 87a987
set -g fish_color_autosuggestion 625e5a
set -g fish_color_valid_path --underline

# Pager colors
set -g fish_pager_color_progress 625e5a
set -g fish_pager_color_prefix 8ba4b0
set -g fish_pager_color_completion c5c9c5
set -g fish_pager_color_description 625e5a
set -g fish_pager_color_selected_background --background=2d4f67

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
