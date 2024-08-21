#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status.

# Default values
CONFIG_FILE=""

# Function to print usage
print_usage() {
    echo "Usage: $0 [-c CONFIG_FILE]"
    echo "  -c CONFIG_FILE    Path to .gitconfig file"
    echo "  -h                Display this help message"
    echo
    echo "Configuration File Format:"
    echo "The configuration file should be in the standard .gitconfig format."
    echo "Example:"
    echo "[user]"
    echo "    name = John Doe"
    echo "    email = john.doe@example.com"
    echo "[core]"
    echo "    editor = vim"
    echo "... (other git configurations)"
}

# Parse command-line arguments
while getopts "c:h" opt; do
    case ${opt} in
        c ) CONFIG_FILE=$OPTARG ;;
        h ) print_usage; exit 0 ;;
        \? ) print_usage; exit 1 ;;
    esac
done

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install Git
install_git() {
    if ! command_exists git; then
        echo "Git is not installed. Installing Git..."
        if command_exists apt-get; then
            sudo apt-get update
            sudo apt-get install -y git
        elif command_exists brew; then
            brew install git
        elif command_exists dnf; then
            sudo dnf install -y git
        elif command_exists pacman; then
            sudo pacman -S --noconfirm git
        else
            echo "Error: Supported package manager not found. Please install Git manually."
            exit 1
        fi
    else
        echo "Git is already installed."
    fi
}

# Configure Git
configure_git() {
    if [[ -n "$CONFIG_FILE" ]]; then
        if [[ -f "$CONFIG_FILE" ]]; then
            echo "Applying Git configurations from $CONFIG_FILE"
            while IFS= read -r line || [[ -n "$line" ]]; do
                # Remove leading/trailing whitespace
                line=$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
                
                # Skip empty lines and comments
                if [[ -z "$line" ]] || [[ "$line" == \#* ]]; then
                    continue
                fi

                # Check if line is a section header
                if [[ "$line" == \[*] ]]; then
                    current_section=$(echo "$line" | tr -d '[]')
                    continue
                fi

                # Parse key-value pairs
                if [[ "$line" == *=* ]]; then
                    key=$(echo "$line" | cut -d= -f1 | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
                    value=$(echo "$line" | cut -d= -f2- | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
                    git config --global "$current_section.$key" "$value"
                    echo "Set $current_section.$key to $value"
                fi
            done < "$CONFIG_FILE"
        else
            echo "Error: Configuration file not found: $CONFIG_FILE"
            exit 1
        fi
    else
        echo "No .gitconfig file provided. Skipping custom Git configuration."
    fi
}

# Function to generate SSH key
generate_ssh_key() {
    local git_email=$(git config --global user.email)
    if [ -z "$git_email" ]; then
        echo "Error: Git email is not set. Please configure your Git email first."
        return 1
    fi

    if [ ! -f ~/.ssh/id_ed25519 ]; then
        echo "Generating new SSH key..."
        ssh-keygen -t ed25519 -C "$git_email" -f ~/.ssh/id_ed25519 -N ""
        eval "$(ssh-agent -s)"
        ssh-add ~/.ssh/id_ed25519
        echo "New SSH key generated and added to ssh-agent."
        echo "Please add the following public key to your GitHub account:"
        cat ~/.ssh/id_ed25519.pub
    else
        echo "SSH key already exists. Skipping generation."
    fi
}

# Function to install GitHub CLI
install_github_cli() {
    if ! command_exists gh; then
        echo "Installing GitHub CLI..."
        if command_exists apt-get; then
            curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
            sudo apt update
            sudo apt install gh
        elif command_exists brew; then
            brew install gh
        elif command_exists dnf; then
            sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
            sudo dnf install gh
        elif command_exists pacman; then
            sudo pacman -S github-cli
        else
            echo "Error: Unsupported package manager. Please install GitHub CLI manually."
            return 1
        fi
    else
        echo "GitHub CLI is already installed."
    fi
}

# Function to set up GitHub CLI
setup_github_cli() {
    echo "Setting up GitHub CLI..."
    gh auth login --web
}

# Function to update .zshrc
update_zshrc() {
    local zshrc="$HOME/.zshrc"
    if [ -f "$zshrc" ]; then
        if ! grep -q "export GPG_TTY=" "$zshrc"; then
            echo 'export GPG_TTY=$(tty)' >> "$zshrc"
            echo "Added GPG_TTY export to .zshrc"
        else
            echo "GPG_TTY export already exists in .zshrc"
        fi
    else
        echo 'export GPG_TTY=$(tty)' > "$zshrc"
        echo "Created .zshrc with GPG_TTY export"
    fi
    echo "To apply changes to your current session, run: source $zshrc"
}

# Main script execution
echo "Starting Git and GitHub setup and configuration..."
install_git
configure_git
generate_ssh_key

if install_github_cli; then
    setup_github_cli
else
    echo "GitHub CLI installation failed. Please install manually if needed."
fi

update_zshrc

echo "Git and GitHub setup and configuration completed."
echo "Remember to add your SSH public key to your GitHub account if you haven't already."
echo "To apply the .zshrc changes, restart your terminal or run: source ~/.zshrc"