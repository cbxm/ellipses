#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status.

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install curl if not already installed
install_curl() {
    if ! command_exists curl; then
        echo "curl is not installed. Installing curl..."
        if command_exists apt-get; then
            sudo apt-get update
            sudo apt-get install -y curl
        elif command_exists brew; then
            brew install curl
        elif command_exists dnf; then
            sudo dnf install -y curl
        elif command_exists pacman; then
            sudo pacman -S --noconfirm curl
        else
            echo "Error: Supported package manager not found. Please install curl manually."
            exit 1
        fi
    else
        echo "curl is already installed."
    fi
}

# Install NVM (Node Version Manager)
install_nvm() {
    echo "Installing NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash

    # Load NVM
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

    # Verify NVM installation
    if command_exists nvm; then
        echo "NVM has been successfully installed."
    else
        echo "Error: NVM installation failed."
        exit 1
    fi
}

# Install latest stable Node.js version and npm using NVM
install_nodejs_and_npm() {
    echo "Installing the latest stable version of Node.js and npm..."
    nvm install stable
    nvm use stable
    nvm alias default stable

    # Verify Node.js installation
    if command_exists node; then
        echo "Node.js has been successfully installed."
        echo "Node.js version: $(node -v)"
    else
        echo "Error: Node.js installation failed."
        exit 1
    fi

    # Ensure npm is installed and up to date
    if command_exists npm; then
        echo "npm is installed. Updating to the latest version..."
        npm install -g npm@latest
        echo "npm version: $(npm -v)"
    else
        echo "Error: npm installation failed."
        exit 1
    fi
}

# Main script execution
echo "Starting Node.js, NVM, and npm installation..."
install_curl
install_nvm
install_nodejs_and_npm
echo "Installation completed successfully."
echo "Please restart your terminal or run 'source ~/.bashrc' (or your shell's equivalent) to start using Node.js, NVM, and npm."