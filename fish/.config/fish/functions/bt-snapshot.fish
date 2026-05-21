function bt-snapshot --description "Bundle Bluetooth diagnostics into a tarball for sharing"
    set -l ts (date +%Y%m%d-%H%M%S)
    set -l workdir (mktemp -d -t bt-snapshot.XXXXXX)
    set -l snapdir $workdir/bt-snapshot-$ts
    set -l outfile $HOME/bt-snapshot-$ts.tar.gz

    mkdir -p $snapdir
    echo "Collecting bt-snapshot-$ts ..."

    # btmon binary traces are root-owned at 0600 — pull via sudo.
    # current.btsnoop is live (being written); copy gives us a stable read.
    sudo -A cp /var/log/btmon/current.btsnoop $snapdir/btmon-current.btsnoop 2>/dev/null
    sudo -A cp /var/log/btmon/current.btsnoop.1.gz $snapdir/btmon-previous.btsnoop.gz 2>/dev/null
    sudo -A chown $USER:$USER $snapdir/btmon-* 2>/dev/null

    # Journals: bluetoothd + kernel BT lines. 3 hours of context.
    journalctl -u bluetooth --since "3 hours ago" --no-pager > $snapdir/journal-bluetoothd.log
    journalctl -k --since "3 hours ago" --no-pager | grep -iE "bluetooth|hci|btusb|usb 3-3" > $snapdir/journal-kernel-bt.log

    # Adapter + paired-device state.
    bluetoothctl show > $snapdir/bluetoothctl-show.txt 2>&1
    bluetoothctl devices Paired > $snapdir/bluetoothctl-devices.txt 2>&1

    # Verify the MT7922 mitigations are still in place.
    begin
        echo "=== BT USB power/control ==="
        cat /sys/bus/usb/devices/3-3/power/control 2>/dev/null
        echo "=== BT USB runtime_status ==="
        cat /sys/bus/usb/devices/3-3/power/runtime_status 2>/dev/null
        echo "=== mt7921e disable_aspm ==="
        cat /sys/module/mt7921e/parameters/disable_aspm 2>/dev/null
        echo "=== btusb enable_autosuspend ==="
        cat /sys/module/btusb/parameters/enable_autosuspend 2>/dev/null
        echo "=== Device setup events this boot ==="
        journalctl -k -b 0 --no-pager | grep "Device setup" | wc -l
    end > $snapdir/power-state.txt

    # Bundle.
    tar -czf $outfile -C $workdir bt-snapshot-$ts
    rm -rf $workdir

    echo "Snapshot written to: $outfile"
    ls -lh $outfile
    echo ""
    echo "Decode HCI trace locally with:  btmon -r <unpacked>/btmon-current.btsnoop | less"
end
