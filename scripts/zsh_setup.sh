#!/bin/bash

#!/bin/bash

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

# Function to install Zsh
install_zsh() {
    print_color "YELLOW" "Updating package lists..."
    sudo apt update

    print_color "YELLOW" "Installing Zsh..."
    sudo apt install -y zsh
}

# Function to set Zsh as the default shell
set_zsh_default() {
    print_color "YELLOW" "Setting Zsh as the default shell..."
    chsh -s $(which zsh)
}

# Function to install Oh My Zsh (optional)
install_oh_my_zsh() {
    print_color "YELLOW" "Would you like to install Oh My Zsh? (y/n)"
    read -r install_omz

    if [[ $install_omz =~ ^[Yy]$ ]]; then
        print_color "YELLOW" "Installing Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    else
        print_color "YELLOW" "Skipping Oh My Zsh installation."
    fi
}

# Function to verify installation
verify_installation() {
    if command_exists zsh; then
        print_color "GREEN" "Zsh installed successfully."
        zsh --version
    else
        print_color "RED" "Error: Zsh installation failed."
        exit 1
    fi
}

# Main installation process
main() {
    print_color "YELLOW" "Starting Zsh installation process..."

    install_zsh
    set_zsh_default
    verify_installation
    install_oh_my_zsh

    print_color "GREEN" "Installation complete. Please log out and log back in for the changes to take effect."
    print_color "YELLOW" "After logging back in, your default shell will be Zsh."
}

# Run the main function
main