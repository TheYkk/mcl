#!/bin/sh

set -ex

KERNEL_VERSION=4.17.3
MUSL_VERSION=1.1.19
BUSYBOX_VERSION=1.28.4
DROPBEAR_VERSION=2018.76
SYSLINUX_VERSION=6.03
IPTABLES_VERSION=1.6.2
DOCKER_VERSION=18.03.1-ce

build=/build
rootfs=$build/rootfs/
isoimage=$build/isoimage/

config() { echo "CONFIG_$2=$1" >> .config; }

download_sources() {
  wget -O kernel.tar.xz \
    http://kernel.org/pub/linux/kernel/v4.x/linux-$KERNEL_VERSION.tar.xz

  wget -O musl.tar.gz \
    http://www.musl-libc.org/releases/musl-$MUSL_VERSION.tar.gz

  wget -O busybox.tar.bz2 \
    http://busybox.net/downloads/busybox-$BUSYBOX_VERSION.tar.bz2

  wget -O dropbear.tar.bz2 \
    https://matt.ucc.asn.au/dropbear/dropbear-$DROPBEAR_VERSION.tar.bz2

  wget -O syslinux.tar.xz \
    http://kernel.org/pub/linux/utils/boot/syslinux/syslinux-$SYSLINUX_VERSION.tar.xz

  wget -O iptables.tar.bz2 \
    https://netfilter.org/projects/iptables/files/iptables-$IPTABLES_VERSION.tar.bz2

  wget -O docker.tgz \
    https://download.docker.com/linux/static/stable/x86_64/docker-$DOCKER_VERSION.tgz

  tar -xf kernel.tar.xz
  tar -xf musl.tar.gz
  tar -xf busybox.tar.bz2
  tar -xf dropbear.tar.bz2
  tar -xf syslinux.tar.xz
  tar -xf iptables.tar.bz2
  tar -xf docker.tgz
}

build_musl() {
  (
  cd musl-$MUSL_VERSION
  ./configure \
    --prefix=/usr

  make
  make DESTDIR=$rootfs install
  )
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
    --disable-wtmp \
    --disable-syslog

  make PROGRAMS="dropbear dbclient dropbearkey scp" strip
  make DESTDIR=$rootfs install
  )
}

build_iptables() {
  (
  cd iptables-$IPTABLES_VERSION
  ./configure  \
    --prefix=/usr \
    --enable-libipq \
    --disable-nftables \
    --enable-static

  make
  make DESTDIR=$rootfs install
  )
}

install_docker() {
  upx docker/*
  mv docker/* $rootfs/usr/bin/
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

  # Basic Config
  config y BLK_DEV_INITRD
  config y IKCONFIG
  config y IKCONFIG_PROC
  config y DEVTMPFS
  config minimal DEFAULT_HOSTNAME

  # Docker Basics
  config y NAMESPACES
  config y NET_NS
  config y PID_NS
  config y IPC_NS
  config y UTS_NS
  config y CGROUPS
  config y CGROUP_CPUACCT
  config y CGROUP_DEVICE
  config y CGROUP_FREEZER
  config y CGROUP_SCHED
  config y CPUSETS
  config y MEMCG
  config y KEYS
  config y VETH
  config y BRIDGE
  config y BRIDGE_NETFILTER
  config y NF_NAT_IPV4
  config y IP_NF_FILTER
  config y IP_NF_TARGET_MASQUERADE
  config y NETFILTER_XT_MATCH_ADDRTYPE
  config y NETFILTER_XT_MATCH_CONNTRACK
  config y NETFILTER_XT_MATCH_IPVS
  config y IP_NF_NAT
  config y NF_NAT
  config y NF_NAT_NEEDED
  config y POSIX_MQUEUE
  config y DEVPTS_MULTIPLE_INSTANCES

  # Docker Storage
  config y BLK_DEV_DM
  config y DM_THIN_PROVISIONING
  config y OVERLAY_FS

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
build_musl
build_busybox
build_dropbear
build_iptables
install_docker
build_rootfs
build_kernel
build_iso
