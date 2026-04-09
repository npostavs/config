#!/bin/sh

set -e

if [ "$1" = upgrade ] ; then
    echo 'upgrade (postrm): not updating hwdb or keyd (redundant)'
else
    echo "kbd-conf [$*]: applying updated hwdb..."
    systemd-hwdb update
    udevadm trigger

    echo "kbd-conf [$*]: reloading keyd..."
    keyd.rvaiya reload
fi
