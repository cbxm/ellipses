#!/bin/sh

#####   SETUP   #####

# TODO: backup all the .config folders that I'll be symlinking later.



#####   git   ##### 

# Git Setup and Configuration Script
#
# This script sets up Git, configures user settings, and generates a GPG key for signing commits.
# It can be called from a parent script and can use a configuration file for settings.
#
# Usage from a parent script:
#   ./git_setup.sh -c script_configs/git.conf
#
# The config file (git.conf) should be in the format output by 'git config --list', e.g.:
#   user.name=Jane Doe
#   user.email=jane.doe@example.com
#   core.editor=vim
#
# If no config file is provided, or if certain settings are missing, the script will prompt for input.
# Command-line arguments take precedence over config file settings.
#
# For full usage information, run: ./git_setup.sh -h

./git_setup.sh -c ./setup_configs/git.conf


#####   node   #####

# Node.js, NVM, and npm Installation Script
# -----------------------------------------
# This script installs the latest stable versions
# of Node.js and npm; and v0.40.0 of NVM.
#
# Usage:
#   1. When called from a parent setup script:
#      source /path/to/this/script.sh
#
#   2. To run standalone:
#      chmod +x /path/to/this/script.sh
#      /path/to/this/script.sh
#
# Note: After running this script, restart your terminal or run:
#       source ~/.bashrc (or your shell's equivalent)
#       to start using Node.js, NVM, and npm.
#
# Dependencies:
#   - curl (will be installed if not present)
#   - Git (required for NVM, but not installed by this script)

source node_setup.sh


#####   python   #####

# Node.js, NVM, and npm Installation Script
# -----------------------------------------
# This script installs Python 3, python-is-python3, pip, pipx, and Poetry on Ubuntu.
# It also sets up autocompletions for pipx.
#
# Usage:
#   1. When called from a parent setup script:
#      source /path/to/this/script.sh
#
#   2. To run standalone:
#      chmod +x /path/to/this/script.sh
#      /path/to/this/script.sh
#
# Note: After running this script, restart your terminal or run:
#       source ~/.bashrc (or your shell's equivalent)
#       to start using Python, pipx, and Poetry.
#
# Dependencies:
#   - curl (will be installed if not present)

source python_setup.sh
source ~/.bashrc


#####    dotbot   #####

#!/bin/bash

# Flexible Dotbot Installation and Configuration Script for Ubuntu
# ----------------------------------------------------------------
# This script installs Dotbot, a tool for managing dotfiles, on Ubuntu systems.
# It installs necessary dependencies (git, python3, pip) and Dotbot itself.
# It can use a provided Dotbot configuration file or create a default one.
#
# Usage:
#   When called from a parent setup script:
#     source /path/to/this/script.sh [path_to_config_file]
#   
#   To run standalone:
#     ./script_name.sh -c [path_to_config_file]
#
# If no configuration file is provided, a default one will be created.
#
# Note: After running this script, restart your terminal or run:
#       source ~/.bashrc
#       to ensure Dotbot is available in your PATH.

source ./dotbot_setup.sh ../dotdot.conf.yaml
source ~/.bashrc






#####   systemd   #####

# link .config/ to dotdot/ folder
ln -s /home/cbxm/dotdot/dots/systemd /home/cbxm/.config/systemd

# Allow user processes to linger
loginctl enable-linger cbxm

# TODO: change KillUserProcesses to equal 'no' in /etc/systemd/logind.conf



#####   zsh   #####

# Zsh Installation Script
# -----------------------
# This script installs Zsh, sets it as the default shell,
# and optionally installs Oh My Zsh.
#
# Usage:
#   1. When called from a parent setup script:
#      source /path/to/this/script.sh
#
#   2. To run standalone:
#      chmod +x /path/to/this/script.sh
#      ./path/to/this/script.sh
#
# Note: After running this script, the user needs to log out
# and log back in for Zsh to become the default shell.
#
# Dependencies:
#   - curl (for Oh My Zsh installation)
#   - sudo privileges (for package installation and changing default shell)

source zsh_setup.sh


#####   neovim   #####



#####   tmux   #####

ln -s /home/cbxm/dotdot/dots/tmux/ /home/cbxm/.config/tmux/

# Install tpm via git
git clone git@github.com:tmux-plugins/tpm ~/dotdot/dots/tmux/plugins/tpm

# The service file is already linked from dots/systemd above,
# so we just enable it for my user right here.
systemctl --user enable tmux.service

# Once this is done, still need to run <C-b><I> to install plugins
~/.config/tmux/plugins/tpm/bin/install_plugins
