function fish_prompt
    set -l last_status $status
    set -l cwd (prompt_pwd)
    
    # ANSI names so the prompt follows the terminal's dark/light theme
    set -l blue blue
    set -l yellow yellow
    set -l red red
    set -l muted brblack
    set -l green green
    
    # Directory
    set_color $blue
    printf '%s' $cwd
    
    # Git branch
    if command -sq git
        set -l branch (git branch --show-current 2>/dev/null)
        if test -n "$branch"
            set_color $muted
            printf ' on '
            set_color $yellow
            printf '%s' $branch
            
            # Dirty indicator
            if not git diff --quiet 2>/dev/null; or not git diff --cached --quiet 2>/dev/null
                set_color $red
                printf ' *'
            end
        end
    end
    
    # Prompt character
    echo
    if test $last_status -eq 0
        set_color $green
    else
        set_color $red
    end
    printf '❯ '
    set_color normal
end
