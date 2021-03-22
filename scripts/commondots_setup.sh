#!/usr/bin/env zsh

# === === === === === === === === ===
# ===  Common Dots Symlink Setup  ===
# === === === === === === === === ===

# Git doesn't let you commit symlinks. So this lets me setup a folder 
# that has my most common rice files "bookmarked" in it.

# === Let's Begin!

# === Setup

mkdir /home/cbxm/.dotdot/dots/commondots

# === Zsh
ln -s /home/cbxm/.config/zsh/zshrc /home/cbxm/.dotdot/dots/commondots/zshrc
ln -s /home/cbxm/.config/zsh/aliases.zshrc /home/cbxm/.dotdot/dots/commondots/aliases.zshrc

# === Tmux
ln -s /home/cbxm/.config/tmux/tmux.conf /home/cbxm/.dotdot/dots/commondots/tmux.conf
ln -s /home/cbxm/.config/tmux/customize.tmux.conf /home/cbxm/.dotdot/dots/commondots/customize.tmux.conf
ln -s /home/cbxm/.config/tmux/statusline.tmux.conf /home/cbxm/.dotdot/dots/commondots/statusline.tmux.conf

# === Neovim
ln -s /home/cbxm/.config/nvim/init.vim /home/cbxm/.dotdot/dot/commondots/init.vim
