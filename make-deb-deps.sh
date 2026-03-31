#!/bin/sh

# Organize debian packages install into metapackage dependencies.
cachedir=$HOME/.cache/$(basename $0).d
mkdeb () {
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
        echo "Version: $(date +%Y.%m.%d.%H.%M)" >> ${cachedir}/$pkgname.equivs.new
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

cat <<EOF | mkdeb np-emacs-build-deps 'Emacs build depends'
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
cat <<EOF | mkdeb np-misc-utils 'Generally useful stuff'
Depends: alsa-utils, aptitude, apt-listchanges, fdisk,
  iputils-ping, traceroute, lsof, nftables, openssh-client,
  wpasupplicant, dhcpcd-base, iw,
  pciutils, usbutils, procps, sudo,
  xdg-utils, unzip,
  vim-tiny, equivs,
  iproute2, ifupdown
EOF

cat <<EOF | mkdeb np-desktop 'My desktop/wm etc'
Depends: i3, xorg, dmenu, x-terminal-emulator, dzen2, lua5.2, lua-posix
EOF

# openjdk version 25 in particular needed for audiveris.
cat <<EOF | mkdeb np-dev 'General dev stuff'
Depends: autoconf, git, gcc, g++, cmake, ccache, openjdk-25-jdk
EOF

# llama.cpp needs libssl to download models
cat <<EOF | mkdeb np-llm 'packages for llm dev'
Depends: libssl-dev,
  python3-setuptools, python3-wheel, python3-venv,
  amdgpu-install, rocm
EOF

echo '==============='

if [ -s $dir/updated-packages ] ; then
    echo UPDATED PACKAGES
    ls $dir/*.deb
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
