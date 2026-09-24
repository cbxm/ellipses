# Subcommands come from the sys_* functions, so new ones complete with no edits here.
# None take file arguments.
complete -c sys -f
complete -c sys -n __fish_use_subcommand -a '(__sys_list)'
