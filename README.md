# Minimal Container Linux OS

> Naming is hard. This is as good a project name as it gets :)
> Suggestions welcome!

This is a fork of (*not backwards portable*) of [minimal-linux-script](https://github.com/ivandavidov/minimal-linux-script)
which adds the following features:

* Docker based build environment (*CI friendly, ~20m build time*)
* Busybox user tools
* Dropbear ssh server
* Docker CE container runtime
* Full Networking support including DHCP
* Ships in a ~50MB ISO
* Boots in ~1s

## Requirements

* 192MB of Memory to boot
* Uses ~64MB at idle
* VirtualBox, QEMU, Proxmox, OpenStack, Cloud Provider or:

Hardware:

*Support coming soon...*

## Things left to do or improve:

* Do more testing
* Polish things up a bit
* Rename the project
* Publish regular images
* Add cloud-init support

![Screenshot](screenshot.png)

**Contributors welcome!**

> Currently not licensed.
> Use at your own risk.
> Absolutely no warraty or support.
