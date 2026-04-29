#!/bin/bash

VERSION_DATE_FMT='+%Y.%m.%d.%H.%M'
# Organize debian packages install into metapackage dependencies.
cachedir=$HOME/.cache/$(basename $0).d
confdir=$HOME/.config/mydebconf/
mkdeb-deps () {
    pkgname=$1
    pkgdesc=$2
    {
        echo "Package: ${pkgname}"
        echo "Description: ${pkgdesc}"
        echo 'Copyright: /dev/null'
        echo 'Section: np-meta'
        echo "README: ${cachedir}/${pkgname}.equivs.new"
        cat
    } > ${cachedir}/$pkgname.equivs.new
    if [ -r ${cachedir}/$pkgname.equivs ] &&
           { grep -v '^Version:' ${cachedir}/$pkgname.equivs |
                 cmp --quiet - ${cachedir}/$pkgname.equivs.new
           } ;
    then
        echo "${pkgname} unchanged"
    else
        echo "Version: $(date ${VERSION_DATE_FMT})" >> ${cachedir}/$pkgname.equivs.new
        equivs-build ${cachedir}/$pkgname.equivs.new
        echo $pkgname >> updated-packages
    fi
}

mkdeb-etc-installer () {
    pkgname=$1
    pkgdesc=$2
    shift 2
    maxdate=0
    {
        echo "Package: ${pkgname}"
        echo "Description: ${pkgdesc}"
        echo 'Copyright: /dev/null'
        echo 'Section: np-etc-installer'
        echo "README: ${cachedir}/${pkgname}.equivs.new"
        printf '%s: %s\n' "$@"
        while [ $# -gt 0 ] ; do
            case "$1" in
                (Postinst|Postrm|Preinst|Prerm)
                    fname=$2
                    ts=$(stat --format=%Y "${confdir}/${fname}")
                    if [ $ts -gt $maxdate ] ; then maxdate=$ts ; fi
                    cp ${confdir}/$fname .
                    ;;
            esac
            shift 2
        done
        echo -n 'Files:'
        while read fname installdir ; do
            ts=$(stat --format=%Y "${confdir}/${fname}")
            if [ $ts -gt $maxdate ] ; then maxdate=$ts ; fi
            cp ${confdir}/$fname .
            echo " ${fname} ${installdir}"
        done
        echo -n "Version: "
        date --date=@${maxdate} "${VERSION_DATE_FMT}"
    } > ${cachedir}/$pkgname.equivs.new
    if [ -r ${cachedir}/$pkgname.equivs ] &&
           cmp --quiet ${cachedir}/$pkgname.equivs ${cachedir}/$pkgname.equivs.new
    then
        echo "${pkgname} unchanged"
    else
        equivs-build ${cachedir}/$pkgname.equivs.new
        echo $pkgname >> updated-packages
    fi
}

# Exit on failure.
set -e

mkdir -p ${cachedir}
dir=$(mktemp --directory --tmpdir meta-debs.XXXXXXXX)
origdir=$PWD
cd $dir

# NOTE: cannot use evtest (or evemu-record) while keyd is running.
args=(Depends 'keyd, evemu-tools'
      Postinst 'kbd-conf-update.sh'
      Postrm   'kbd-conf-update.sh')
cat <<EOF | mkdeb-etc-installer np-kbd 'Keyboard configuration' "${args[@]}"
  90-keyboard.hwdb /etc/udev/hwdb.d/
  keyd.conf /etc/keyd/
EOF

args=(Depends 'nftables, ifupdown, udhcpd'
      Preinst  'net-conf-divert.sh'
      Postinst 'net-conf-update.sh'
      Postrm   'net-conf-update.sh')
cat <<EOF | mkdeb-etc-installer np-network 'Network configuration' "${args[@]}"
  network-interface-share-inet-over-eth.conf /etc/network/interfaces.d
  nftables.conf /etc/
  udhcpd.conf /etc/
EOF

cat <<EOF | mkdeb-deps np-emacs-build-deps 'Emacs build depends'
Depends: libacl1-dev, libasound2-dev, libcairo2-dev, libdbus-1-dev,
  libgccjit-14-dev, libgif-dev, libgmp-dev, libgnutls28-dev,
  libgpm-dev, libgtk-3-dev, libharfbuzz-dev, libjpeg-dev,
  libjpeg62-turbo-dev, liblcms2-dev, liblockfile-dev, libm17n-dev,
  libncurses-dev, libotf-dev, libpng-dev, librsvg2-dev, libselinux1-dev,
  libsqlite3-dev, libsystemd-dev, libtiff-dev, libtree-sitter-dev,
  libwebp-dev, libxaw7-dev, libxml2-dev, xaw3dg-dev, zlib1g-dev,
  imagemagick, imagemagick-7.q16, texinfo
EOF

# iproute2 for 'ip addr...'; ifupdown needed to get network connection!
# But possibly can replace with iwd?
cat <<EOF | mkdeb-deps np-misc-utils 'Generally useful stuff'
Depends: alsa-utils, aptitude, apt-listchanges, fdisk,
  iputils-ping, traceroute, lsof, nftables, openssh-client,
  wpasupplicant, dhcpcd-base, iw,
  pciutils, usbutils, procps, sudo,
  xdg-utils, unzip, mupdf-tools,
  ffmpeg,
  vim-tiny, equivs,
  iproute2, ifupdown
EOF

cat <<EOF | mkdeb-deps np-desktop 'My desktop/wm etc'
Depends: i3, xorg, dmenu, x-terminal-emulator, dzen2, lua5.2, lua-posix,
  scrot, dunst, hledger, mupdf
EOF

# openjdk version 25 in particular needed for audiveris.
cat <<EOF | mkdeb-deps np-dev 'General dev stuff'
Depends: autoconf, git, gcc, g++, cmake, ccache, openjdk-25-jdk
EOF

# llama.cpp needs libssl to download models
cat <<EOF | mkdeb-deps np-llm 'packages for llm dev'
Depends: libssl-dev,
  python3-setuptools, python3-wheel, python3-venv,
  amdgpu-install, rocm
EOF

echo '==============='

if [ -s $dir/updated-packages ] ; then
    echo UPDATED PACKAGES
    ls -1 $dir/*.deb
    chmod o+rx $dir
    sudo apt install $dir/*.deb
    for deb in $dir/*.deb ; do
        # $dir/<pkgname>_<date-version>_all.deb --> <pkgname>_<date-version> --> <pkgname>
        pkgname_versioned=$(basename --suffix=_all.deb $deb)
        pkgname=${pkgname_versioned%%_*}
        mv ${cachedir}/$pkgname.equivs.new ${cachedir}/$pkgname.equivs
    done
else
    echo NO CHANGES
    cd $origdir
    rmdir $dir
fi
