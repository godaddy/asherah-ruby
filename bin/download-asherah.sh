#!/usr/bin/env bash

root=$( cd "$(dirname "${BASH_SOURCE[0]}")/.." ; pwd -P )
dir=$root/lib/asherah/native/

rm -rf $dir

wget --content-disposition --directory-prefix $dir/  \
  https://github.com/godaddy/asherah-cobhan/releases/download/current/libasherah-arm64.dylib \
  https://github.com/godaddy/asherah-cobhan/releases/download/current/libasherah-arm64.so \
  https://github.com/godaddy/asherah-cobhan/releases/download/current/libasherah-x64.dylib \
  https://github.com/godaddy/asherah-cobhan/releases/download/current/libasherah-x64.so \
  || exit 1
