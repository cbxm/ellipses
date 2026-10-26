function sys_portal --description "Patch the COSMIC portal's screen-share freeze (#389), or restore it"
    set -l pkg xdg-desktop-portal-cosmic
    set -l bin /usr/libexec/xdg-desktop-portal-cosmic
    set -l unit org.freedesktop.impl.portal.desktop.cosmic
    set -l cache ~/.cache/sys-portal
    set -l src $cache/xdg-desktop-portal-cosmic
    set -l built $src/target/release/xdg-desktop-portal-cosmic

    # pkgver, because $version is a read-only fish variable.
    set -l pkgver (dpkg-query -W -f '${db:Status-Status} ${Version}' $pkg 2>/dev/null | string replace -rf '^installed ' '')
    if test -z "$pkgver"
        echo "sys portal: $pkg is not installed" >&2
        return 1
    end

    switch "$argv[1]"
        case patch
            _sys_portal_patch
        case restore
            _sys_portal_restore
        case ''
            _sys_portal_status
            _sys_portal_usage
        case '*'
            _sys_portal_usage >&2
            return 1
    end
end

function _sys_portal_usage
    echo "usage: sys portal patch    build the fix for the installed version and install it"
    echo "       sys portal restore  put the packaged binary back"
    echo "fix for https://github.com/pop-os/xdg-desktop-portal-cosmic/issues/389"
end

function _sys_portal_status -S
    set -l state "modified: matches neither the package nor the last sys portal build"
    if _sys_portal_official $bin
        set state official
    else if test -f $built; and cmp -s $bin $built
        set state "patched by sys portal"
    end
    echo "$pkg $pkgver: $state"
end

function _sys_portal_patch -S
    set -l proto $cache/cosmic-protocols
    set -l patch (path dirname (functions --details sys_portal))/sys_portal.patch

    set -l missing
    for dep in libxkbcommon-dev libpipewire-0.3-dev libgbm-dev libegl-dev libclang-dev
        dpkg-query -W -f '${db:Status-Status}' $dep 2>/dev/null | string match -q installed
        or set -a missing $dep
    end
    command -q cargo; or set -a missing cargo
    if set -q missing[1]
        echo "sys portal: missing build dependencies; install them with:" >&2
        echo "  sai $missing" >&2
        return 1
    end

    # Pop's version string ends in the upstream commit it was built from.
    set -l commit (string split '~' -- $pkgver)[-1]
    if not string match -qr '^[0-9a-f]{7,40}$' -- $commit
        echo "sys portal: no upstream commit at the end of version $pkgver" >&2
        return 1
    end

    mkdir -p $cache; or return
    _sys_portal_fetch https://github.com/pop-os/xdg-desktop-portal-cosmic $src $commit; or return
    # Also drops the [patch] table a previous run appended to Cargo.toml.
    git -C $src checkout --quiet --force --detach $commit; or return

    set -l revs (string match -rg '^source = "git\+https://github\.com/pop-os/cosmic-protocols[^#]*#([0-9a-f]{40})"$' <$src/Cargo.lock | sort -u)
    if test (count $revs) -ne 1
        echo "sys portal: can't pick one cosmic-protocols rev from Cargo.lock (found: $revs)" >&2
        return 1
    end
    set -l rev $revs[1]
    _sys_portal_fetch https://github.com/pop-os/cosmic-protocols $proto $rev; or return

    # Leave a tree that is already $rev plus exactly this patch untouched. Rewriting
    # dispatch.rs bumps its mtime, and cargo then rebuilds everything that depends on
    # client-toolkit (libcosmic, iced, cosmic-files).
    set -l want (git -C $proto patch-id --stable <$patch | string split -f1 ' ')
    if test -z "$want"
        echo "sys portal: can't read the fix from $patch" >&2
        return 1
    end
    set -l have (git -C $proto diff | git -C $proto patch-id --stable | string split -f1 ' ')
    if test "$(git -C $proto rev-parse HEAD)" != $rev -o "$have" != "$want"
        git -C $proto checkout --quiet --force --detach $rev; or return
        if git -C $proto apply --check --reverse $patch 2>/dev/null
            echo "sys portal: cosmic-protocols $rev already has the fix, so the packaged portal does too; nothing to patch"
            _sys_portal_status
            return 0
        end
        if not git -C $proto apply $patch
            echo "sys portal: the fix no longer applies to cosmic-protocols $rev; check whether #389 was fixed upstream" >&2
            return 1
        end
    end

    # --locked can't be used: the path patch rewrites the cosmic-protocols lock entries.
    printf '%s\n' '' \
        '[patch."https://github.com/pop-os/cosmic-protocols"]' \
        'cosmic-protocols = { path = "../cosmic-protocols" }' \
        'cosmic-client-toolkit = { path = "../cosmic-protocols/client-toolkit" }' >>$src/Cargo.toml
    or return
    cargo build --release --manifest-path $src/Cargo.toml --target-dir $src/target --bin xdg-desktop-portal-cosmic
    or return

    # A [patch] that matches nothing is only a cargo warning ("Patch ... was not used"),
    # and the lock then still pins the git source: the build is unpatched.
    if string match -q '*"git+https://github.com/pop-os/cosmic-protocols*' <$src/Cargo.lock
        echo "sys portal: cargo didn't use the patched cosmic-protocols (look for \"Patch ... was not used\" above); not installing" >&2
        return 1
    end

    # Keep the official binary so restore works offline, and after the repo moves on.
    if _sys_portal_official $bin
        cp $bin $cache/official; or return
    end
    sudo install -m 0755 $built $bin; or return
    if not _sys_portal_restart
        echo "sys portal: the portal didn't start; see journalctl --user -u $unit, or run sys portal restore" >&2
        return 1
    end
    _sys_portal_status
end

function _sys_portal_restore -S
    if not _sys_portal_official $bin
        # A saved copy is only used if it's byte-identical to what this version shipped.
        set -l saved
        for candidate in $cache/official $bin.orig-*
            if _sys_portal_official $candidate
                set saved $candidate
                break
            end
        end
        if set -q saved[1]
            sudo install -m 0755 $saved $bin; or return
        else if not sudo apt install --reinstall $pkg=$pkgver
            echo "sys portal: apt couldn't reinstall $pkgver (offline, or the repo has moved on; sys up installs the newer official build)" >&2
            return 1
        end
        _sys_portal_restart; or return
    end

    # Copies left in /usr/libexec by hand-patching before sys portal existed.
    set -l stray $bin.orig-*
    if set -q stray[1]
        sudo rm -f $stray; or return
    end
    _sys_portal_status
end

# Succeeds if the file is byte-identical to the binary the installed package shipped.
function _sys_portal_official -S -a file
    set -l sums (dpkg-query --control-path $pkg md5sums 2>/dev/null); or return
    set -l expected (string match -- "*  "(string sub -s 2 -- $bin) <$sums | string split -f1 ' ')
    test -n "$expected" -a -f "$file"; or return
    set -l actual (md5sum <$file | string split -f1 ' ')
    test "$actual" = "$expected"
end

# Restarting the portal ends any screen share in progress, so it waits for none to be running.
function _sys_portal_restart -S
    if command -q pw-cli; and pw-cli ls Node 2>/dev/null | string match -q '*node.name = "cosmic-screencast"'
        echo "screen share in progress, so the portal wasn't restarted. The new binary runs from its next start, or now with:"
        echo "  systemctl --user restart $unit"
        return 0
    end
    systemctl --user restart $unit
end

# Clones the repo if needed and makes sure the commit is available locally.
function _sys_portal_fetch -a url dir commit
    if not test -d $dir/.git
        git clone $url $dir; or return
    end
    git -C $dir rev-parse --quiet --verify "$commit^{commit}" >/dev/null; and return
    git -C $dir fetch origin; or return
    if not git -C $dir rev-parse --quiet --verify "$commit^{commit}" >/dev/null
        echo "sys portal: $commit not found in $url" >&2
        return 1
    end
end
