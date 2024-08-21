# ========== Zsh Theme Config ==========================================================

# The primary battleground for any shell-oriented theming operations

# === Zsh Herself ======================================================================

ZSH_THEME="dracula"				# Classic.


# === fzf ==============================================================================

# Yes, more vamp-vibes.
export FZF_DEFAULT_OPTS='
  --layout=reverse
  --inline-info
  --height=10
  --color fg:255,bg:236,hl:84,fg+:255,bg+:236,hl+:215 
  --color info:141,prompt:84,spinner:212,pointer:212,marker:212
'
