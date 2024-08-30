# ========== .dotdot, meet zsh. We're good friends. ====================================

#
# My primary configuration for zsh.
#
# Theme setup and personal aliases are kept in their own rc files and sourced from here.
# 

# ========== SETUP =====================================================================

# ========== powerlevel10k =============================================================

# Enables Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.

if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi


# === Zsh ==============================================================================

# Define a folder for private funcs, to be lazy-loaded by `zsh`,
# and prepend it to $fpath, to enable overriding of other functions.
# fpath=( ~/.config/zsh/funcs "${fpath[@]}")


# === Oh-My-Zsh ========================================================================

export ZSH=$HOME/.oh-my-zsh				# path to oh-my-zsh directory

HYPHEN_INSENSITIVE="true"				# ignore hyphens for autocompletion
DISABLE_UNTRACKED_FILES_DIRTY="true"	# ignore untracked git files at the prompt
 
plugins=(
	# common-aliases           			# better to handpick from these
	fzf                        			# CTRL+R(hist), T(dirs), & ALT-C(cd) for fzf at the prompt
	git                        			# the common git aliases I love
	gitignore                  			# useful .gitignore tool. use `gi [template] >> [file]`
	gh									# auto-completion for the GitHub CLI
	magic-enter							# bind 'git status -u .' and 'ls -lh .' to Enter
	poetry                     			# auto-invoke a poetry env when inside a project
	sudo                       			# double-tap ESC to go get the damn `sudo`
	z                          			# fast jumping to visited directories by 'frecency'
	zsh-autosuggestions        			# command completion based on history
	zsh-syntax-highlighting    			# highlight commands as you type. must be sourced last.
)


# ========== ENVIRONMENT ===============================================================

# === Add'l Rice Files =================================================================

DOT_ZSHRC="$HOME/.config/zsh"		# base directory

source "$DOT_ZSHRC/aliases.zshrc"	# a place for ALL my aliases...
# source "$DOT_ZSHRC/theme.zshrc"		# and then one for all my theme stuff! [deprecated, theme is now inline]


# ========== THEME =====================================================================

ZSH_THEME="powerlevel10k/powerlevel10k"				# Classic.

# To customize prompt, run `p10k configure` or edit ~/.config/p10k/.p10k.zsh
[[ ! -f ~/.config/p10k/.p10k.zsh ]] || source ~/.config/p10k/.p10k.zsh




# === Variables ========================================================================

EDITOR='code'					# Set my editor.
OS=$(awk '/DISTRIB_ID=/' /etc/*-release | sed 's/DISTRIB_ID=//' | tr '[:upper:]' '[:lower:]')
											# Fetch the current distro's name.

# === Extra Paths ======================================================================

# A few platforms keep their bin folders in the home directory.
# We're just adding them to the $PATH so that we can use the 
# utilities we've installed through them.

PATH="$HOME/go/bin:$PATH"          		# for Golang
PATH="$HOME/.local/bin:$PATH"      		# and misc executables
GEM_HOME="$HOME/.config/gems"           # Install Ruby Gems to ~/.config/gems/
PATH="$GEM_HOME/bin:$PATH"              # and add that to $PATH
PATH="$HOME/.poetry/bin:$PATH"          # Fix for WSL: should be benign on *nix
PATH="$HOME/bin:$PATH"					# Add user's `bin` to PATH


# === Misc =============================================================================

export GPG_TTY=$(tty)					# fixes gpg passphrase prompts

# zstyle ':omz:update' mode disabled  	# disable automatic updates
# zstyle ':omz:update' mode auto      	# update automatically without asking
zstyle ':omz:update' mode reminder  	# just remind me to update when it's time


# ========== KICK-OFF ==================================================================

source $ZSH/oh-my-zsh.sh 													# punt OMZ
[[ ! -f ~/.config/p10k/.p10k.zsh ]] || source ~/.config/p10k/.p10k.zsh 		# punt p10k
