#!/bin/sh

ARCH=x86_64
MIRROR="http://dl-2.alpinelinux.org/alpine"
BRANCH="latest-stable"
VERSION=2.10.0-r0

wget "$MIRROR/$BRANCH/main/$ARCH/apk-tools-static-$VERSION.apk"
tar xvf apk-tools-static-$VERSION.apk
mv ./sbin/apk.static /sbin/apk
apk add -U -X "$MIRROR/$BRANCH/main" --allow-untrusted --initdb
echo "$MIRROR/$BRANCH/main" > /etc/apk/repositories
