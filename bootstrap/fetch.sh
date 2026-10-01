#!/usr/bin/env bash
# Obtain the pinned bootstrap without requiring a bootstrap compiler or Git.
set -euo pipefail
umask 022
directory=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
destination=$(realpath -m "${1:-$directory/out/bootstrap.tar.zst}")
expected=2703bd4a9bd9fbdddb00cca71cbcced18b769e338df099c8809f28070d50316a
url=https://github.com/magnet-linux/packages/releases/download/v0.1.0/bootstrap-x86_64-linux-musl.tar.zst
verify() { test "$(sha256sum "$1" | cut -d ' ' -f 1)" = "$expected"; }
if test -f "$destination"; then
  verify "$destination" || { echo "Checksum mismatch: $destination" >&2; exit 1; }
else
  test ! -e "$destination" && test ! -L "$destination"
  mkdir -p "$(dirname "$destination")"
  temporary=$(mktemp "$(dirname "$destination")/.bootstrap.XXXXXXXX")
  trap 'rm -f "$temporary"' EXIT
  curl --fail --location --retry 3 --proto '=https' --proto-redir '=https' \
    "$url" -o "$temporary"
  verify "$temporary" || { echo 'Bootstrap checksum mismatch.' >&2; exit 1; }
  chmod 0644 "$temporary"
  mv "$temporary" "$destination"
fi
printf '%s\n' "$destination"
