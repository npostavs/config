#!/bin/sh

nftables_diversion=$(dpkg-divert --listpackage /etc/nftables.conf)

if [ "$1" = remove ] ; then
    if [ "$nftables_diversion" = np-network ] ; then
        dpkg-divert --rename --remove /etc/nftables.conf
    fi
else
    if [ "$nftables_diversion" != np-network ] ; then
        dpkg-divert --package np-network --rename --add /etc/nftables.conf
    fi
fi
