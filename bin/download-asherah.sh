#!/usr/bin/env bash

set -eu

files=${*:-libasherah-arm64.dylib libasherah-arm64.so libasherah-x64.dylib libasherah-x64.so}

root=$( cd "$(dirname "${BASH_SOURCE[0]}")/.." ; pwd -P )
DIR=$root/lib/asherah/native
mkdir "$DIR" 2> /dev/null || true

VERSION=v0.1.2

for file in $files; do
  rm "$DIR/$file" 2> /dev/null || true
  url=https://github.com/godaddy/asherah-cobhan/releases/download/$VERSION/$file
  curl -s -L --fail --retry 999 --retry-max-time 0 "$url" --output "$DIR/$file"
  sha256sum "$DIR/$file"
done
