#!/usr/bin/env bash

set -euo pipefail

out=$PWD/stubs

log() {
  echo "$@" >&2
}

while getopts "o:s:" opt; do
  case $opt in
    o) # output
      out=$OPTARG
      ;;
    s) # sysroot
      sysroot=$OPTARG
      ;;
    \?)
      log "invalid option specified"
      exit 1
      ;;
  esac
done

mkdir -p "$out"

while read -r lib; do
  @out@/libexec/stubify.sh -r -s "$sysroot" -o "$out" "/$lib"
done < <(cd "$sysroot" && find usr/lib -name '*.dylib' -type f)

@out@/libexec/frameworks-tbd.sh -s "$sysroot" -o "$out"

@out@/libexec/add-aliases.sh -s "$sysroot" -o "$out"

@out@/libexec/link-frameworks.rb "$out/System/Library/**/*.tbd"
