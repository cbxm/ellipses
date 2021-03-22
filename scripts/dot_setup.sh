#!/usr/bin/env zsh

# === === === === === ===
# === Dot File Setup  ===
# === === === === === ===

# This script's intended purpose is to symlink all the 
# ~/.config/ I use and THAT'S IT. Backup happens elsewhere.
# TODO: Gee, I really should turn this all into a Python script.


# === Here we go! ===

# === Zsh

ln -s /home/cbxm/.dotdot/dots/zsh /home/cbxm/.config/zsh
ln -s /home/cbxm/.config/zsh/zshrc /home/cbxm/.zshrc

# === Tmux
ln -s /home/cbxm/.dotdot/dots/tmux /home/cbxm/.config/tmux

# === Neovim
ln -s /home/cbxm/.dotdot/dots/nvim /home/cbxm/.config/nvim

# === Glow
ln -s /home/cbxm/.dotdot/dots/glow /home/cbxm/.config/glow


