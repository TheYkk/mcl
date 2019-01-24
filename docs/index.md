---
layout: default
title: "Minimal Container Linux"
---

# Minimal Container Linux

[![Build Status](https://travis-ci.org/prologic/minimal-container-linux.svg)](https://travis-ci.org/prologic/minimal-container-linux)

Minimal Container Linux (`mcl`) is a Linux Host OS designed specifically to
run Containers. Right now it supports the Docker Engine runtime, however it is
possible to support other Container runtimes (*and maybe planned*).

`mcl` consists of the following components:

- [Linux](https://kernel.org) Kernel
- [Busybox](https://busybox.net/about.html) Userspace
- [Dropbear](https://matt.ucc.asn.au/dropbear/dropbear.html) SSH Daemon
- [Docker](https://www.docker.com/) Container Runtime

## Quick start

Try out `mcl` quickly and easily with [QEMU](https://www.qemu.org/):

```#!bash
$ $ curl -# -L -O $(curl -s https://api.github.com/repos/prologic/minimal-container-linux/releases/latest | grep -E 'browser_download_url.*\.iso' | cut -d '"' -f 4)
$ qemu-system-x86_64 -m 512M -boot d -cdrom mcl.iso -device virtio-rng-pci
```

:exclamation: It is important that you provide a HWRNG to the Guest VM or the
VM will boot very slowly as virtual environments have few sources of entropy.

## Screenshot

![Screenshot](screenshot.png)
