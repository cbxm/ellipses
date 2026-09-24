function conserve --description "Toggle Lenovo battery conservation mode (~80% charge cap)"
    set -l flag /sys/bus/platform/devices/VPC2004:00/conservation_mode
    set -l types /sys/class/power_supply/BAT0/charge_types

    if not test -e $flag -a -e $types
        echo "conserve: no ideapad conservation_mode/charge_types on this machine"
        return 1
    end

    # Write charge_types rather than $flag: it sets the conservation and Rapid Charge
    # EC bits together, so they never end up both on. Read $flag, because charge_types
    # reads intermittently fail with EINVAL on Carina's EC.
    set -l cur (cat $flag); or return
    if test "$cur" = 1
        echo Fast | sudo tee $types >/dev/null; or return
    else
        echo Long_Life | sudo tee $types >/dev/null; or return
    end

    set cur (cat $flag); or return
    if test "$cur" = 1
        echo "conservation mode: on (caps at ~80%, Rapid Charge off)"
    else
        echo "conservation mode: off (charges to 100%, Rapid Charge on)"
        echo "note: third-party USB-C chargers drop out 5-21 min after hitting 100%"
    end
end
