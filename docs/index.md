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

## Screenshot

![Screenshot](screenshot.png)
