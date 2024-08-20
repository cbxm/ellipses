#!/bin/bash

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

set -e  # Exit immediately if a command exits with a non-zero status.

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_color() {
    printf "${!1}%s${NC}\n" "$2"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check Ubuntu versionx
check_ubuntu_version() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [ "$NAME" != "Ubuntu" ]; then
            print_color "RED" "Error: This script is designed to run on Ubuntu."
            exit 1
        fi
        print_color "GREEN" "Detected Ubuntu version: $VERSION_ID"
    else
        print_color "RED" "Error: Unable to determine OS version."
        exit 1
    fi
}

# Function to install packages on Ubuntu
install_ubuntu() {
    print_color "YELLOW" "Updating package lists..."
    sudo apt update

    print_color "YELLOW" "Installing Python 3, python-is-python3, and pip..."
    sudo apt install -y python3 python-is-python3 python3-pip
}

# Function to install pipx
install_pipx() {
    print_color "YELLOW" "Installing pipx..."
    sudo apt install -y python3-venv
    python3 -m pip install --user pipx
    python3 -m pipx ensurepath
}

# Function to set up pipx autocompletions
setup_pipx_autocompletions() {
    print_color "YELLOW" "Setting up pipx autocompletions..."
    
    local shell_config
    if [ -n "$ZSH_VERSION" ]; then
        shell_config="$HOME/.zshrc"
    elif [ -n "$BASH_VERSION" ]; then
        shell_config="$HOME/.bashrc"
    else
        print_color "RED" "Unsupported shell. Please add the following line to your shell's configuration file:"
        echo 'eval "$(register-python-argcomplete pipx)"'
        return
    fi

    if grep -q "register-python-argcomplete pipx" "$shell_config"; then
        print_color "GREEN" "Autocompletions already set up in $shell_config"
    else
        echo 'eval "$(register-python-argcomplete pipx)"' >> "$shell_config"
        print_color "GREEN" "Autocompletions added to $shell_config"
    fi
}

# Function to install Poetry using pipx
install_poetry() {
    print_color "YELLOW" "Installing Poetry using pipx..."
    pipx install poetry
}

# Function to verify installation
verify_installation() {
    local command=$1
    local name=$2
    if command_exists "$command"; then
        print_color "GREEN" "$name installed successfully."
        $command --version
    else
        print_color "RED" "Error: $name installation failed."
        exit 1
    fi
}

# Main installation process
main() {
    print_color "YELLOW" "Starting installation process..."

    check_ubuntu_version

    install_ubuntu
    verify_installation python "Python 3"
    verify_installation pip "pip"

    install_pipx
    verify_installation pipx "pipx"

    setup_pipx_autocompletions

    install_poetry
    verify_installation poetry "Poetry"

    print_color "GREEN" "Installation complete. Please restart your terminal or run 'source ~/.bashrc' (or 'source ~/.zshrc' for Zsh) to ensure all installed tools are available in your PATH and autocompletions are activated."
}

# Parse command line arguments
while getopts ":h" opt; do
    case ${opt} in
        h )
            echo "Usage:"
            echo "  $0 [-h]"
            echo "Options:"
            echo "  -h    Display this help message"
            exit 0
            ;;
        \? )
            print_color "RED" "Invalid Option: -$OPTARG" 1>&2
            exit 1
            ;;
    esac
done

# Run the main function
main