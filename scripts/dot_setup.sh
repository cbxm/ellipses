#!/bin/sh

#####   SETUP   #####

# TODO: backup all the .config folders that I'll be symlinking later.



#####   git   ##### 

# git config --global user.name "Caden Bloxham"
# git config --global user.email "cadenblox@gmail.com"
# git config advice.addIgnoredFile false
# TODO: install GPG keys


#####   systemd   #####

# link .config/ to dotdot/ folder
ln -s /home/cbxm/dotdot/dots/systemd /home/cbxm/.config/systemd

# Allow user processes to linger
loginctl enable-linger cbxm

# TODO: change KillUserProcesses to equal 'no' in /etc/systemd/logind.conf



#####   zsh   #####

ln -s /home/cbxm/dotdot/dots/zsh/.zshrc /home/cbxm/.zshrc


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
