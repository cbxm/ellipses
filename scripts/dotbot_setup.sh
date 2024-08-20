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
#     ./script_name.sh [path_to_config_file]
#
# If no configuration file is provided, a default one will be created as ~/ellipses/dotbot.conf.yaml
#
# Note: After running this script, restart your terminal or run:
#       source ~/.bashrc
#       to ensure Dotbot is available in your PATH.

set -e  # Exit immediately if a command exits with a non-zero status.

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored output
print_color() {
    printf "${!1}%s${NC}\n" "$2"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install packages
install_packages() {
    print_color "YELLOW" "Updating package lists..."
    sudo apt update

    print_color "YELLOW" "Installing required packages..."
    sudo apt install -y git python3 python3-pip
}

# Function to install Dotbot
install_dotbot() {
    print_color "YELLOW" "Installing Dotbot..."
    pip3 install --user dotbot

    # Add Dotbot to PATH
    if ! grep -q "export PATH=\$PATH:\$HOME/.local/bin" "$HOME/.bashrc"; then
        echo 'export PATH=$PATH:$HOME/.local/bin' >> "$HOME/.bashrc"
        print_color "GREEN" "Added Dotbot to PATH in .bashrc"
    else
        print_color "GREEN" "Dotbot already in PATH"
    fi
}

# Function to verify installation
verify_installation() {
    if command_exists dotbot; then
        print_color "GREEN" "Dotbot installed successfully."
        dotbot --version
    else
        print_color "RED" "Error: Dotbot installation failed."
        exit 1
    fi
}

# Function to create default Dotbot configuration
create_default_config() {
    local config_dir="$HOME/ellipses"
    local config_file="$config_dir/dotbot.conf.yaml"
    
    print_color "YELLOW" "Creating default Dotbot configuration..."
    
    # Create dotfiles directory
    mkdir -p "$config_dir/dots"

    # Create Dotbot configuration file
    cat > "$config_file" <<EOL
- defaults:
    link:
      relink: true
      create: true

- clean: ['~']

- link:
    ~/.config/nvim: dots/nvim
    ~/.tmux.conf: dots/tmux/.tmux.conf
    ~/.zshrc: dots/zsh/.zshrc

- shell:
    - [git submodule update --init --recursive, Installing submodules]
EOL

    print_color "GREEN" "Default Dotbot configuration created at $config_file"
    print_color "YELLOW" "Note: The paths in dotbot.conf.yaml are relative to $config_dir"
    
    echo "$config_file"
}

# Main installation process
main() {
    local config_file="$1"

    print_color "YELLOW" "Starting Dotbot installation and configuration process..."

    install_packages
    install_dotbot
    verify_installation

    if [ -z "$config_file" ]; then
        config_file=$(create_default_config)
    elif [ ! -f "$config_file" ]; then
        print_color "RED" "Error: Specified configuration file does not exist."
        exit 1
    fi

    print_color "GREEN" "Installation complete. Please restart your terminal or run 'source ~/.bashrc' to ensure Dotbot is available in your PATH."
    print_color "YELLOW" "To use Dotbot with your configuration, run: dotbot -c [config_file.conf.yaml]"
}

# Check if the script is being sourced or run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Script is being run directly
    main "$1"
else
    # Script is being sourced
    # Export the main function so it can be called by the parent script
    export -f main
fi