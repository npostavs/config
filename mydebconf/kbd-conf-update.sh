#!/bin/sh

set -e

echo applying updated hwdb...

systemd-hwdb update
udevadm trigger

echo reloading keyd
keyd.rvaiya reload
