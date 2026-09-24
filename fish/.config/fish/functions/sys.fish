function sys --description "System management commands; run bare or tab-complete to list them"
    if not set -q argv[1]
        __sys_list | while read -l -d \t name desc
            printf '  %-10s %s\n' $name $desc
        end
        return
    end

    if not functions -q sys_$argv[1]
        echo "sys: unknown command '$argv[1]'; run 'sys' to list them" >&2
        return 1
    end
    sys_$argv[1] $argv[2..]
end
