# Packages

Package definitions for [magpkg](https://github.com/magnet-linux/magpkg),
targeting x86-64 Linux with musl.

Builds start from a bootstrap archive containing a compiler, libc, and basic
tools. The package recipes then rebuild musl, binutils, GCC, and the base
utilities from source.

Install magpkg, bubblewrap, and curl on an x86-64 Linux host, then run from
this directory:

```sh
./bootstrap/fetch.sh
magpkg init --store "$PWD/_work/store"
magpkg build --store "$PWD/_work/store" \
  --ext-str "bootstrap-url=file://$PWD/bootstrap/out/bootstrap.tar.zst" \
  bootstrap/seed.jsonnet seed
magpkg build --store "$PWD/_work/store" hello.jsonnet hello
```

`fetch.sh` downloads the pinned bootstrap archive and verifies its SHA-256.
`seed.jsonnet` adds it to magpkg's source cache; the final command builds a
small example package. To build the bootstrap yourself, see the
[bootstrap instructions](bootstrap/README.md).
