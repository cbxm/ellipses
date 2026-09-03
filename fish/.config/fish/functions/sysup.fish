function sysup --description "Update everything: apt, flatpak, brew, uv, bun, cargo, gh ext, fwupd"
    argparse n/dry-run y/yes -- $argv; or return

    set -l yes
    set -q _flag_yes; and set yes -y
    set -l failed

    # Authenticate sudo first so a wrong password aborts before anything runs.
    set -q _flag_dry_run; or sudo -v; or return

    # Upgrade only against fresh lists.
    _sysup_run apt sudo apt update
    and _sysup_run apt sudo apt upgrade $yes

    if command -q flatpak
        _sysup_run flatpak flatpak update $yes
        _sysup_run flatpak flatpak uninstall --unused $yes
    end

    # brew upgrade only auto-updates if the last update is >24h old; force it.
    if command -q brew
        _sysup_run brew brew update
        _sysup_run brew brew upgrade
    end

    if command -q uv
        _sysup_run uv uv self update
        _sysup_run uv uv tool upgrade --all
    end

    if command -q bun
        _sysup_run bun bun upgrade
        _sysup_run bun bun update -g
    end

    if command -q cargo-install-update
        _sysup_run cargo cargo install-update -a
    else if command -q cargo
        echo "cargo: binaries not updated; install cargo-update (cargo install cargo-update)"
    end

    command -q gh; and _sysup_run gh gh extension upgrade --all

    # Firmware: refresh metadata and report only. Installing firmware stays a manual step.
    # get-updates exits 2 when nothing is pending, which is not a failure.
    if command -q fwupdmgr
        _sysup_run fwupd fwupdmgr refresh --force
        _sysup_run fwupd fwupdmgr get-updates
        test $status -eq 2; and set -e failed[-1]
    end

    set_color --bold blue
    echo "== reminders"
    set_color normal

    set -l running (uname -r)
    set -l newest (ls -v /boot | string replace -rf '^vmlinuz-' '' | tail -1)
    if test -n "$newest" -a "$newest" != "$running"
        echo "REBOOT: running kernel $running, newest installed $newest"
    end

    # Debs installed from a local file have no repo and never get upgraded by apt.
    # Old kernel packages also show as local once dropped from the repo; those are
    # autoremove's job, not a manual update, so skip them.
    set -l local_debs (apt list --installed 2>/dev/null | string match -r '^[^/]+(?=.*\[installed,local\])' | string match -v -r '^linux-')
    if test -n "$local_debs"
        echo "MANUAL (not in any apt repo): $local_debs"
    end

    if set -q failed[1]
        set_color --bold red
        echo FAILED:
        printf '  %s\n' $failed
        set_color normal
        return 1
    end
end

# Runs one step, or prints it under --dry-run. -S shares sysup's scope so it can
# read _flag_dry_run and append to failed.
function _sysup_run -S -a label
    set -e argv[1]
    set_color --bold blue
    echo "== $label"
    set_color normal
    if set -q _flag_dry_run
        echo "  $argv"
    else
        $argv
        set -l st $status
        test $st -ne 0; and set -a failed "$label: $argv"
        return $st
    end
end
