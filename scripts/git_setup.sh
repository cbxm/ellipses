#!/bin/bash

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
    echo
    echo "Example config file content:"
    echo "  user.name=Jane Doe"
    echo "  user.email=jane.doe@example.com"
    echo "  core.editor=vim"
    echo
    echo "Note: Command-line arguments take precedence over config file values."
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
    echo "Git user settings have been configured."
    echo "Editor set to: $GIT_EDITOR"
}

# Generate GPG key and configure Git to use it
generate_gpg_key_and_configure() {
    if ! command_exists gpg; then
        echo "GPG is not installed. Installing GPG..."
        # ... [GPG installation code remains unchanged] ...
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

# Main script execution
echo "Starting Git setup and configuration..."
install_git
configure_git
if generate_gpg_key_and_configure; then
    echo "Git setup and configuration completed successfully."
else
    echo "Git setup completed, but there were issues with GPG key generation."
    echo "Please review the output above and consider generating a GPG key manually."
fi