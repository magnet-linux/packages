#!/usr/bin/env bash
# Export a stable package-tree release; an optional seed becomes a separate asset.
set -euo pipefail
umask 022
repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
version=${1:?usage: release.sh VERSION [REF [OUTPUT-DIRECTORY]]}
[[ "$version" =~ ^v[0-9]+\.[0-9]+\.[0-9]+([.-][A-Za-z0-9.-]+)?$ ]] || exit 2
revision=$(git -C "$repo" rev-parse --verify "${2:-HEAD}^{commit}")
epoch=$(git -C "$repo" show -s --format=%ct "$revision")
out=$(realpath -m "${3:-$repo/out/release-$version}")
test ! -e "$out" || { echo "Output already exists: $out" >&2; exit 1; }
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
prefix=packages-$version
mkdir "$scratch/$prefix"
git -C "$repo" archive "$revision" | tar -xf - -C "$scratch/$prefix"
printf 'version=%s\nrevision=%s\n' "$version" "$revision" > "$scratch/$prefix/RELEASE"
mkdir -p "$out"
tar --format=gnu --sort=name --mtime="@$epoch" --owner=0 --group=0 --numeric-owner \
  -C "$scratch" -cf - "$prefix" | gzip -n > "$out/$prefix.tar.gz"
if test -n "${BOOTSTRAP_ARCHIVE:-}"; then
  expected=$(awk '$1 !~ /^#/ && NF {print $1; exit}' "$scratch/$prefix/bootstrap/bootstrap.sha256")
  test "$(sha256sum "$BOOTSTRAP_ARCHIVE" | cut -d ' ' -f 1)" = "$expected" || {
    echo 'Bootstrap checksum mismatch.' >&2; exit 1;
  }
  cp "$BOOTSTRAP_ARCHIVE" "$out/bootstrap-x86_64-linux-musl.tar.zst"
fi
(cd "$out"; sha256sum ./*.tar.* > SHA256SUMS)
printf 'Release assets: %s\n' "$out"
