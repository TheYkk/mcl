#!/bin/sh

qemu-system-x86_64 \
  -m 512M \
  -boot d \
  -cdrom mcl.iso \
  -device virtio-rng-pci
