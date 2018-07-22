#!/bin/sh

set -ex

KERNEL_VERSION=4.17.3
MUSL_VERSION=1.1.19
BUSYBOX_VERSION=1.28.4
DROPBEAR_VERSION=2018.76
SYSLINUX_VERSION=6.03
RNGTOOLS_VERSION=5
IPTABLES_VERSION=1.6.2
DOCKER_VERSION=18.03.1-ce

NUM_JOBS="$(grep ^processor /proc/cpuinfo | wc -l)"

build=/build
rootfs=$build/rootfs/
isoimage=$build/isoimage/

debug() { echo "Dropping into a shell for debugging ..."; /bin/sh; }

config() { 
  if grep "CONFIG_$2" .config; then
    sed -i "s|.*CONFIG_$2.*|CONFIG_$2=$1|" .config
  else
    echo "CONFIG_$2=$1" >> .config
  fi
}

download_syslinux() {
  wget -q -O syslinux.tar.xz \
    http://kernel.org/pub/linux/utils/boot/syslinux/syslinux-$SYSLINUX_VERSION.tar.xz
  tar -xf syslinux.tar.xz
}

download_kernel() {
  wget -q -O kernel.tar.xz \
    http://kernel.org/pub/linux/kernel/v4.x/linux-$KERNEL_VERSION.tar.xz
  tar -xf kernel.tar.xz
}

download_musl() {
  wget -q -O musl.tar.gz \
    http://www.musl-libc.org/releases/musl-$MUSL_VERSION.tar.gz
  tar -xf musl.tar.gz
}

download_busybox() {
  wget -q -O busybox.tar.bz2 \
    http://busybox.net/downloads/busybox-$BUSYBOX_VERSION.tar.bz2
  tar -xf busybox.tar.bz2
}

download_dropbear() {
  wget -q -O dropbear.tar.bz2 \
    https://matt.ucc.asn.au/dropbear/dropbear-$DROPBEAR_VERSION.tar.bz2
  tar -xf dropbear.tar.bz2
}

download_rngtools() {
  wget -q -O rngtools.tar.gz \
    https://downloads.sourceforge.net/sourceforge/gkernel/rng-tools-$RNGTOOLS_VERSION.tar.gz
  tar -xf rngtools.tar.gz
}

download_iptables() {
  wget -q -O iptables.tar.bz2 \
    https://netfilter.org/projects/iptables/files/iptables-$IPTABLES_VERSION.tar.bz2
  tar -xf iptables.tar.bz2
}

download_docker() {
  wget -q -O docker.tgz \
    https://download.docker.com/linux/static/stable/x86_64/docker-$DOCKER_VERSION.tgz
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
  make distclean defconfig -j $NUM_JOBS
  config y STATIC
  config n INCLUDE_SUSv2
  config y INSTALL_NO_USR
  config "\"$rootfs\"" PREFIX
  config y FEATURE_EDITING_VI
  config y TUNE2FS
  config n BOOTCHARTD
  config n INIT
  config n LINUXRC
  config y FEATURE_GPT_LABEL
  config n LPD
  config n LPR
  config n LPQ
  config n RUNSV
  config n RUNSVDIR
  config n SV
  config n SVC
  config n SVLOGD
  config n HUSH
  config n CHAT
  config n CONSPY
  config n RUNLEVEL
  config n PIPE_PROGRESS
  config n RUN_PARTS
  config n START_STOP_DAEMON
  yes "" | make oldconfig
  make \
    EXTRA_CFLAGS="-Os -s -fno-stack-protector -U_FORTIFY_SOURCE" \
    busybox install -j $NUM_JOBS
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

  make \
    EXTRA_CFLAGS="-Os -s -fno-stack-protector -U_FORTIFY_SOURCE" \
    DESTDIR=$rootfs \
    PROGRAMS="dropbear dbclient dropbearkey scp" \
    strip install -j $NUM_JOBS
  ln -sf /usr/bin/dbclient $rootfs/usr/bin/ssh
  )
}

build_rngtools() {
  (
  cd rng-tools-$RNGTOOLS_VERSION
  ./configure \
    --prefix=/usr \
    --sbindir=/usr/sbin \
    CFLAGS="-static" LIBS="-l argp"
  make
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

  make \
    EXTRA_CFLAGS="-Os -s -fno-stack-protector -U_FORTIFY_SOURCE" \
    -j $NUM_JOBS
  make DESTDIR=$rootfs install
  )
}

install_docker() {
  mv docker/* $rootfs/usr/bin/
}

write_metadata() {
  # Setup /etc/os-release with some nice contents
  latestTag="$(git describe --abbrev=0 --tags)"
  latestRev="$(git rev-parse --short HEAD)"
  fullVersion="$(echo "${latestTag}" | cut -c2-)"
  majorVersion="$(echo "${latestTag}" | cut -c2- | cut -d '.' -f 1,2)"
  cat > $rootfs/etc/os-release <<EOF
NAME=minimcal-container-linuux
VERSION=$fullVersion
ID=mcl
ID_LIKE=tcl
VERSION_ID=$fullVersion
PRETTY_NAME="Minimal Container Linux $fullVersion (TCL $majorVersion); $latestRev"
ANSI_COLOR="1;34"
HOME_URL="https://mcl.host/"
SUPPORT_URL="https://github.com/prologic/minimal-container-linux"
BUG_REPORT_URL="https://github.com/prologic/minimal-container-linux/issues"
EOF

  cat > $rootfs/usr/bin/mcl <<EOF
#!/bin/sh

echo "Minimal Container Linux (MCL) v${fullVersion} @ ${latestRev}"

# End of file
EOF
chmod +x $rootfs/usr/bin/mcl
}

build_rootfs() {
  (
  cd rootfs
  rm -rf usr/man
  rm -rf usr/include
  find . | cpio -R root:root -H newc -o | gzip -9 > ../rootfs.gz
  )
}

sync_rootfs() {
  (
  mkdir rootfs.old
  cd rootfs.old
  zcat $build/rootfs.gz | cpio -idm
  rsync -aru . $rootfs
  )
}

build_kernel() {
  (
  cd linux-$KERNEL_VERSION
  make mrproper defconfig kvmconfig -j $NUM_JOBS

  # Disable debug symbols in kernel => smaller kernel binary.
  sed -i "s/^CONFIG_DEBUG_KERNEL.*/\\# CONFIG_DEBUG_KERNEL is not set/" .config

  # Enable the EFI stub
  sed -i "s/.*CONFIG_EFI_STUB.*/CONFIG_EFI_STUB=y/" .config

  # Basic Config
  config y BLK_DEV_INITRD
  config y IKCONFIG
  config y IKCONFIG_PROC
  config y DEVTMPFS
  config n DEBUG_KERNEL
  config mcl DEFAULT_HOSTNAME

  # RNG
  config y HW_RANDOM_VIRTIO

  # Network Driers
  config y VIRTIO
  config y VIRTIO_PCI
  config y VIRTIO_MMIO
  config y VIRTIO_CONSOLE
  config y VIRTIO_BLK
  config y VIRTIO_NET
  config y 8139TOO
  config y 8139CP

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
  make \
    CFLAGS="-Os -s -fno-stack-protector -U_FORTIFY_SOURCE" \
    bzImage -j $NUM_JOBS
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
    -o ../mcl.iso \
    -b isolinux.bin \
    -c boot.cat \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    ./
  )
}

build_clouddrive() {
  xorrisofs -J -r -V cidata -o ./clouddrive.iso clouddrive/
}

build_all() {
  download_musl
  build_musl

  download_busybox
  build_busybox

  download_dropbear
  build_dropbear

  download_rngtools
  build_rngtools

  download_iptables
  build_iptables

  download_docker
  install_docker

  download_kernel
  build_kernel

  write_metadata
  build_rootfs

  download_syslinux
  build_iso
  build_clouddrive
}

repack() {
  sync_rootfs
  write_metadata
  build_rootfs
  download_syslinux
  build_iso
  build_clouddrive
}

case "${1}" in
  repack)
    repack
    ;;
  *)
    build_all
    ;;
esac
