# ========== .dotdot aliases ===========================================================

# These aliases are geared towards general quality-of-life improvements inside 
# the terminal. These are meant to make working inside of zsh just a little bit
# easier, without focusing too heavily on specific workflows.


# === BEGIN ============================================================================

alias gal='alias | grep --color'        # `grep` active aliases. You're welcome.
alias vim='nvim'                        # Because muscle memory. I'm welcome.

# === Decoration =======================================================================

alias clk='tty-clock -ct -f "%a, %B %d" -C 4 -D'	# without date
alias clkd='tty-clock -ct -f "%a, %B %d" -C 4'	# with date


# === `ls` shortcuts ===================================================================

alias ls='ls --group-directories-first'	# not currently working. overridden by OMZ, rn.

alias ls1='ls -1'                       # `ls` on one line per entry
alias lsa1='ls -A1'                     #  + hidden files
alias lse='ls -A'                       # the hidden files view I like most


# === Git ==============================================================================

alias gaf='git add -f'


# === "The System" =====================================================================

alias task='vim ~/me/.task.md'
alias todo='vim ~/me/.todo.md'
alias inbx='vim ~/me/.inbox.md'
alias note='vim ~/me/_scratch.md'

# === Quick Edit Various Dots [currently broken] =======================================

# main configs
alias dotz='vim ~/.zshrc'
alias dotalias='vim ~/.config/zsh/aliases.zshrc'
alias dotnvim='vim ~/.config/nvim/init.vim'
alias dottmux='vim ~/.config/tmux/'
# alias doti3='vim ~/.config/i3/i3.config'        # I think this path might be wrong


# === tmux shortcuts

alias tls='tmux ls'				# list sessions
alias t='tmux attach -t Main'           	# attach to systemd-launched session
alias tm='tmux -f $TMUX_CONF new -d'		# new session with no name
alias tmn='tmux -f $TMUX_CONF new -d -s'	# new session with specified name
alias tmm='tmux -f $TMUX_CONF new -d -s Main'	# start new session with name "main"



# === === SORT LATER === ===


alias td='termdown -bs --no-figlet'
alias pom='td --title "pomo" 30m'
alias pomb='td --title "pomo break" 5m'
alias tt='td --title'
alias tt-mc='td --title "To Market Close" 2pm'
alias tt-bed='td --title "Bedtime" 10pm'
alias tt-focus='td --title "rem. in session"'

