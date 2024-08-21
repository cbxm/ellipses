#!/bin/bash

# Git and GitHub Setup and Configuration Script
#
# This script sets up Git, configures user settings, generates a GPG key for signing commits,
# sets up SSH for GitHub, installs the GitHub CLI, and configures the necessary environment.
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

set -e  # Exit immediately if a command exits with a non-zero status.

# Default values
GIT_USERNAME=""
GIT_EMAIL=""
GIT_EDITOR=""
CONFIG_FILE=""

# Function to print usage
print_usage() {
    echo "Usage: $0 [-u GIT_USERNAME] [-e GIT_EMAIL] [-d GIT_EDITOR] [-c CONFIG_FILE]"
    echo "  -u GIT_USERNAME   Set Git username"
    echo "  -e GIT_EMAIL      Set Git email"
    echo "  -d GIT_EDITOR     Set Git editor (default: nvim if available, otherwise nano)"
    echo "  -c CONFIG_FILE    Path to configuration file"
    echo "  -h                Display this help message"
    echo
    echo "Configuration File Format:"
    echo "The configuration file should be in the format output by 'git config --list'."
    echo "Each line should be in the format 'key=value'. Relevant keys are:"
    echo "  user.name         Git username"
    echo "  user.email        Git email"
    echo "  core.editor       Preferred text editor"
}

# Parse command-line arguments
while getopts "u:e:d:c:h" opt; do
    case ${opt} in
        u ) GIT_USERNAME=$OPTARG ;;
        e ) GIT_EMAIL=$OPTARG ;;
        d ) GIT_EDITOR=$OPTARG ;;
        c ) CONFIG_FILE=$OPTARG ;;
        h ) print_usage; exit 0 ;;
        \? ) print_usage; exit 1 ;;
    esac
done

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to set the default editor
set_default_editor() {
    if command_exists nvim; then
        echo "nvim"
    elif command_exists vim; then
        echo "vim"
    else
        echo "nano"
    fi
}

# Function to read configuration file
read_config_file() {
    if [[ -f "$CONFIG_FILE" ]]; then
        while IFS='=' read -r key value
        do
            case "$key" in
                user.name)
                    [[ -z "$GIT_USERNAME" ]] && GIT_USERNAME="$value"
                    ;;
                user.email)
                    [[ -z "$GIT_EMAIL" ]] && GIT_EMAIL="$value"
                    ;;
                core.editor)
                    [[ -z "$GIT_EDITOR" ]] && GIT_EDITOR="$value"
                    ;;
            esac
        done < "$CONFIG_FILE"
    else
        echo "Error: Configuration file not found: $CONFIG_FILE"
        exit 1
    fi
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
    # If config file is provided, read from it
    if [[ -n "$CONFIG_FILE" ]]; then
        read_config_file
    fi

    # If values are still empty, prompt user
    if [[ -z "$GIT_USERNAME" ]]; then
        read -p "Enter your Git username: " GIT_USERNAME
    fi
    if [[ -z "$GIT_EMAIL" ]]; then
        read -p "Enter your Git email: " GIT_EMAIL
    fi
    if [[ -z "$GIT_EDITOR" ]]; then
        GIT_EDITOR=$(set_default_editor)
        read -p "Enter your preferred text editor (default: $GIT_EDITOR): " user_editor
        if [[ -n "$user_editor" ]]; then
            if command_exists "$user_editor"; then
                GIT_EDITOR="$user_editor"
            else
                echo "Warning: $user_editor is not installed. Using $GIT_EDITOR instead."
            fi
        fi
    else
        if ! command_exists "$GIT_EDITOR"; then
            echo "Warning: $GIT_EDITOR is not installed. Using $(set_default_editor) instead."
            GIT_EDITOR=$(set_default_editor)
        fi
    fi

    git config --global user.name "$GIT_USERNAME"
    git config --global user.email "$GIT_EMAIL"
    git config --global core.editor "$GIT_EDITOR"
    git config --global init.defaultbranch "main"
    
    # Configure GitHub URLs to use SSH instead of HTTPS
    git config --global url."ssh://git@github.com/".insteadOf "https://github.com/"
    
    # Add GPG configurations
    git config --global gpg.program gpg
    git config --global commit.gpgsign true
    
    echo "Git user settings have been configured."
    echo "Editor set to: $GIT_EDITOR"
    echo "GitHub URLs will now use SSH instead of HTTPS."
    echo "GPG signing has been enabled for commits."
}

# Generate GPG key and configure Git to use it
generate_gpg_key_and_configure() {
    if ! command_exists gpg; then
        echo "GPG is not installed. Installing GPG..."
        if command_exists apt-get; then
            sudo apt-get update
            sudo apt-get install -y gnupg
        elif command_exists brew; then
            brew install gnupg
        elif command_exists dnf; then
            sudo dnf install -y gnupg
        elif command_exists pacman; then
            sudo pacman -S --noconfirm gnupg
        else
            echo "Error: Supported package manager not found. Please install GPG manually."
            exit 1
        fi
    fi

    echo "Generating GPG key..."
    echo "You will be prompted to enter a passphrase for your GPG key. Please choose a strong, unique passphrase."
    echo "This passphrase will be required when signing commits or tags with Git."

    # Function to generate GPG key
    generate_key() {
        passphrase=$1
        gpg --batch --gen-key <<EOF
%echo Generating a basic OpenPGP key
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Name-Real: $GIT_USERNAME
Name-Email: $GIT_EMAIL
Expire-Date: 0
Passphrase: $passphrase
%commit
%echo done
EOF
    }

    # Try to generate key with user input
    if [ -t 0 ]; then  # Check if script is running in an interactive terminal
        read -s -p "Enter passphrase for GPG key: " passphrase
        echo
        read -s -p "Confirm passphrase: " passphrase_confirm
        echo

        if [ "$passphrase" != "$passphrase_confirm" ]; then
            echo "Error: Passphrases do not match. Aborting GPG key generation."
            return 1
        fi

        if ! generate_key "$passphrase"; then
            echo "Error: GPG key generation failed. Trying alternative method."
            return 1
        fi
    else
        echo "Not running in interactive mode. Using alternative method for GPG key generation."
        return 1
    fi

    # If the above fails, try an alternative method
    if [ $? -ne 0 ]; then
        passphrase=$(openssl rand -base64 32)
        if ! generate_key "$passphrase"; then
            echo "Error: GPG key generation failed. Please try generating the key manually."
            return 1
        fi
        echo "GPG key generated with a random passphrase. Please change it immediately using:"
        echo "gpg --edit-key $GIT_EMAIL"
    fi

    echo "Retrieving GPG key information..."
    GPG_KEY_ID=$(gpg --list-secret-keys --keyid-format=long | grep sec | tail -1 | awk '{print $2}' | awk -F'/' '{print $2}')

    if [ -z "$GPG_KEY_ID" ]; then
        echo "Error: Could not extract GPG key ID. Please check your GPG setup and try again."
        return 1
    fi

    echo "Configuring Git to use GPG key..."
    git config --global user.signingkey $GPG_KEY_ID
    git config --global commit.gpgsign true

    echo "Git has been configured to use GPG key: $GPG_KEY_ID"
    
    # Display GPG public key for adding to GitHub
    echo "Your GPG public key (add this to your GitHub account):"
    gpg --armor --export $GPG_KEY_ID

    echo "Note: You will need to enter your GPG key passphrase when signing commits or tags."
    echo "To avoid entering it repeatedly, you can configure gpg-agent to cache your passphrase."
}

# Function to generate SSH key
generate_ssh_key() {
    if [ ! -f ~/.ssh/id_ed25519 ]; then
        echo "Generating new SSH key..."
        ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f ~/.ssh/id_ed25519 -N ""
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
if generate_gpg_key_and_configure; then
    echo "GPG key generation and configuration completed successfully."
else
    echo "GPG key setup had issues. Please review the output above."
fi

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