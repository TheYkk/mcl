#!/bin/sh

set -ex

KERNEL_VERSION=4.17.3
BUSYBOX_VERSION=1.28.4
DROPBEAR_VERSION=2018.76
SYSLINUX_VERSION=6.03

build=/build
rootfs=$build/rootfs/
isoimage=$build/isoimage/

config() { echo "CONFIG_$2=$1" >> .config; }

download_sources() {
  wget -O kernel.tar.xz \
    http://kernel.org/pub/linux/kernel/v4.x/linux-$KERNEL_VERSION.tar.xz

  wget -O busybox.tar.bz2 \
    http://busybox.net/downloads/busybox-$BUSYBOX_VERSION.tar.bz2

  wget -O dropbear.tar.bz2 \
    https://matt.ucc.asn.au/dropbear/dropbear-$DROPBEAR_VERSION.tar.bz2

  wget -O syslinux.tar.xz \
    http://kernel.org/pub/linux/utils/boot/syslinux/syslinux-$SYSLINUX_VERSION.tar.xz

  tar -xf kernel.tar.xz
  tar -xf busybox.tar.bz2
  tar -xf dropbear.tar.bz2
  tar -xf syslinux.tar.xz
}

build_busybox() {
  (
  cd busybox-$BUSYBOX_VERSION
  make distclean defconfig
  sed -i "s/.*CONFIG_STATIC.*/CONFIG_STATIC=y/" .config
  make busybox install
  cp -a _install/* "$rootfs"
  )
}

build_dropbear() {
  (
  cd dropbear-$DROPBEAR_VERSION
  ./configure \
    --prefix=/usr \
    --mandir=/usr/man \
    --enable-static \
    --disable-zlib \
    --disable-syslog

  make PROGRAMS="dropbear dbclient dropbearkey scp"
  make strip
  make DESTDIR=$rootfs install
  )
}

build_rootfs() {
  (
  cd rootfs
  rm -f linuxrc
  chmod u+s bin/busybox
  find . | cpio -R root:root -H newc -o | gzip > ../rootfs.gz
  )
}

build_kernel() {
  (
  cd linux-$KERNEL_VERSION
  make mrproper defconfig kvmconfig
  config y BLK_DEV_INITRD
  config y IKCONFIG
  config y IKCONFIG_PROC
  config y DEVTMPFS
  config minimal DEFAULT_HOSTNAME
  yes "" | make oldconfig
  make bzImage
  cp arch/x86/boot/bzImage ../kernel.gz
  )
}

build_iso() {
  test -d "$isoimage" || mkdir "$isoimage"
  cp rootfs.gz "$isoimage"
  cp kernel.gz "$isoimage"
  cp syslinux-$SYSLINUX_VERSION/bios/core/isolinux.bin "$isoimage"
  cp syslinux-$SYSLINUX_VERSION/bios/com32/elflink/ldlinux/ldlinux.c32 "$isoimage"
  echo 'default kernel.gz initrd=rootfs.gz append quiet' > "$isoimage/isolinux.cfg"

  (
  cd "$isoimage"
  xorriso \
    -as mkisofs \
    -o ../minimal.iso \
    -b isolinux.bin \
    -c boot.cat \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    ./
  )
}

download_sources
build_busybox
build_dropbear
build_rootfs
build_kernel
build_iso
