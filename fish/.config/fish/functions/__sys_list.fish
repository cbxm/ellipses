# Every sys_<name> function on the function path is a `sys` subcommand. Prints
# "name<TAB>description" lines, the format both `sys` and its completions consume.
function __sys_list
    for f in (functions --all | string match 'sys_*')
        printf '%s\t%s\n' (string replace sys_ '' $f) (functions --details --verbose $f)[5]
    end
end
