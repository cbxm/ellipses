#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status.

# ... [Previous parts of the script remain unchanged] ...

# Configure Git
configure_git() {
    # ... [Previous configuration code remains unchanged] ...

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

# ... [Other functions remain unchanged] ...

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