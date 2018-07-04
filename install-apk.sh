#!/bin/sh

wget http://dl-cdn.alpinelinux.org/alpine/latest-stable/main/x86_64/apk-tools-static-2.10.0-r0.apk
tar xvf apk-tools-static-2.10.0-r0.apk
mv ./sbin/apk.static /sbin/
apk -X http://dl-2.alpinelinux.org/alpine//latest-stable/main -U --allow-untrusted --initdb
