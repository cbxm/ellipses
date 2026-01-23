function fish_prompt
    set -l last_status $status
    set -l cwd (prompt_pwd)
    
    # Colors (Kanagawa Dragon)
    set -l blue 8ba4b0
    set -l yellow c4b28a
    set -l red c4746e
    set -l muted 625e5a
    set -l green 8a9a7b
    
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
