#!/bin/sh

# Get the highest tag number
VERSION="$(git describe --abbrev=0 --tags)"
VERSION=${VERSION:-'0.0.0'}

# Get number parts
MAJOR="${VERSION%%.*}"; VERSION="${VERSION#*.}"
MINOR="${VERSION%%.*}"; VERSION="${VERSION#*.}"
PATCH="${VERSION%%.*}"; VERSION="${VERSION#*.}"

# Increase version
PATCH=$((PATCH+1))

TAG="${1}"

if [ "${TAG}" = "" ]; then
  TAG="${MAJOR}.${MINOR}.${PATCH}"
fi

echo "Releasing ${TAG} ..."

git-chglog --next-tag="${TAG}" --output CHANGELOG.md
git ci -a -m "Release ${TAG}"
git push
github-release release \
  -u prologic \
  -r minimal-container-linux \
  -t "${TAG}"  \
  -n "${TAG}" \
  -d "$(git-chglog --next-tag "${TAG}" "${TAG}" | tail -n+5)"
git pull --tags
