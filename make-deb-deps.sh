#!/bin/sh

# Organize debian packages install into metapackage dependencies.

mkdeb () {
    pkgname=$1
    pkgdesc=$2
    {
        echo "Package: ${pkgname}"
        echo "Description: ${pkgdesc}"
        echo 'Copyright: /dev/null'
        echo 'Section: np-meta'
        echo "README: ${PWD}/${pkgname}.equivs"
        echo "Version: $(date +%Y.%m.%d.%H.%M)"
        cat
    } > $pkgname.equivs
    equivs-build $pkgname.equivs
}

# Exit on failure.
set -e

dir=$(mktemp --directory --tmpdir meta-debs.XXXXXXXX)
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

cat <<EOF | mkdeb np-misc-utils 'Generally useful stuff'
Depends: alsa-utils, aptitude, apt-listchanges, fdisk,
  iputils-ping, traceroute, lsof, nftables, openssh-client,
  wpasupplicant, dhcpcd-base, iw,
  pciutils, usbutils, procps, sudo,
  xdg-utils,
  vim-tiny, equivs
EOF

cat <<EOF | mkdeb np-desktop 'My desktop/wm etc'
Depends: i3, xorg, x-terminal-emulator, dzen2, lua5.2, lua-posix
EOF

# openjdk version 25 in particular needed for audiveris.
cat <<EOF | mkdeb np-dev 'General dev stuff'
Depends: autoconf, git, gcc, g++, cmake, ccache, openjdk-25-jdk
EOF

cat <<EOF | mkdeb np-llm 'packages for llm dev'
Depends: libssl-dev,
  python3-setuptools, python3-wheel, amdgpu-install
EOF

ls $dir/*.deb
chmod o+rx $dir
sudo apt install $dir/*.deb
