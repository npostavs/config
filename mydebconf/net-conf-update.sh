#!/bin/sh

set -e
echo "net-conf [$*]: applying nftables.conf..."
nft -f /etc/nftables.conf
