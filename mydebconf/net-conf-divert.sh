#!/bin/sh

nftables_diversion=$(dpkg-divert --listpackage /etc/nftables.conf)
udhcpd_diversion=$(dpkg-divert --listpackage /etc/udhcpd.conf)

is_removing_package=
if [ "$1" = remove ] ; then
    is_removing_package=t
fi

handle_conf_file() {
    file=$1
    diversion=$(dpkg-divert --listpackage "$file")
    if [ "$is_removing_package" = t ] ; then
        if [ "$diversion" = np-network ] ; then
            dpkg-divert --rename --remove "$file"
        fi
    else
        if [ "$diversion" != np-network ] ; then
            dpkg-divert --package np-network --rename --add "$file"
        fi
    fi
}

handle_conf_file /etc/nftables.conf
handle_conf_file /etc/udhcpd.conf
