#!/bin/sh

git-chglog --next-tag=v0.0.6 --output CHANGELOG.md
git ci -a -m "Relase v0.0.6"
git push
github-release prologic/minimal-container-linux v0.0.6 master "$(git-chglog --next-tag v0.0.6 v0.0.6 | tail -n+5)" ""
git pull --tags
