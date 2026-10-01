# Packages

The minimal bootable system, configuration skeleton, manual installation
procedure, and headless QEMU test live in [magnet-linux](https://github.com/magnet-linux/magnet-linux/blob/main/magnet-linux/README.md).

`doas.jsonnet` builds OpenDoas 6.8.2 with the shared Linux-PAM package. The base
system installs `/bin/doas` as root-owned mode 4755. Editable authorization and
PAM files are provisioned separately; the initial rule requires the invoking
`wheel` member's password to run a command as root. Timestamp caching is not
compiled in.

`fuzzel.jsonnet` builds the native Wayland application launcher for the Hyprland
profile. It shares Foot's libraries, supports PNG and bundled NanoSVG icons,
and also provides `fuzzel --dmenu` for piped choices. The upstream example and
manual sources are installed under `/share`; the distro skeleton provisions
editable `/etc/xdg/fuzzel/fuzzel.ini` defaults separately.

`adwaita-cursors.jsonnet` installs the Xcursor assets and compatibility aliases
from GNOME's hash-pinned Adwaita 48.1 release, without the application icons.
The graphical session selects Adwaita for both the desktop and login screen.

The [audio recipes](audio/README.md) provide PipeWire, WirePlumber, PulseAudio
client compatibility and playback/recording tools for the graphical session.

The [network recipes](network/README.md) provide NetworkManager, nmcli, nmtui,
wpa_supplicant and polkit for desktop networking under perp.

`chrony.jsonnet` provides chronyd and chronyc for both the headless and desktop
systems, with `libcap.jsonnet` for dropping privileges. This initial build is
an ordinary NTP client; NTS is not enabled. The skeleton provisions an editable
`/etc/chrony.conf` and a perp service, with persistent state in `/var/lib/chrony`.

`notifications.jsonnet` provides Mako, its standalone basu D-Bus library, and
libnotify (including `notify-send`). It shares the existing Wayland, Pango,
Cairo and GdkPixbuf libraries and requires no systemd or elogind daemon.
Hyprland starts it in the user's D-Bus session, with activation available for
recovery. `/etc/xdg/mako/config` supplies the initial appearance and timeouts.

## Bootstrap hello

Install a released [magpkg](https://github.com/magnet-linux/magpkg) executable
and bubblewrap on an x86-64 Linux host, then run from this tree's root:

```sh
./bootstrap/fetch.sh
magpkg init --store "$PWD/_work/store"
magpkg build --store "$PWD/_work/store" \
  --ext-str "bootstrap-url=file://$PWD/bootstrap/out/bootstrap.tar.zst" \
  bootstrap/seed.jsonnet seed
magpkg build --store "$PWD/_work/store" hello.jsonnet hello
```

The seed helper populates the source cache by its content hash. Normal recipes
can then use that seed without changing their identities. Installed Magnet
systems retain a copy at `/var/lib/magpkg/bootstrap.tar.zst` too. The seed can
also be built from source using [bootstrap/README.md](bootstrap/README.md).
No sibling source repository is required.

## Magpkg

`magpkg.jsonnet` builds the standalone `magnet-linux/magpkg` v0.1.0 source
release, pinned by SHA-256:

```sh
magpkg build --store "$PWD/_work/store" magpkg.jsonnet magpkg
```

The resulting `/bin/magpkg` is statically linked. Its runtime dependencies
include Bash and GNU shell utilities, bubblewrap, and CA certificates. The
kernel must support the namespaces required by bubblewrap.

`go.jsonnet` packages the official Go 1.26.4 Linux/amd64 binary toolchain as a
build dependency; rebuilding Go from source is a follow-up.
`magpkg-modules.libsonnet` pins module downloads and the recipe constructs an
offline module proxy, verifies `go.sum`, runs tests, and builds the executable.
The magpkg project also publishes a static binary for installation hosts.

## Releases and integration

This tree is released independently of the package manager and distro. Its
initial format uses magpkg v0.1.0. The distro pins a tree archive by SHA-256,
while Git remains an optional development workflow.

```sh
make test
BOOTSTRAP_ARCHIVE=/path/to/bootstrap.tar.zst ./scripts/release.sh v0.1.0 HEAD
```

The tests evaluate every package graph with the released magpkg Go library;
Go is needed for these maintainer tests, but not for using downloaded recipes.
The release script exports committed source into `packages-v0.1.0.tar.gz`,
records its Git revision in `RELEASE`, and creates SHA256SUMS. With the optional
`BOOTSTRAP_ARCHIVE`, it also publishes the verified bootstrap as a separate
asset. Upload these files as GitHub release assets and retain their exact
bytes. Run the script twice at the same commit to check reproducibility.

`linux.libsonnet` exports `kernel(config, name)` for callers to provide a kernel
configuration. System profiles, service configuration and Magnet-specific
session launchers belong to the distro. All recipe imports stay within this
repository; application patches and shared libraries remain here.

## Core

`core.jsonnet` rebuilds the core toolchain and userland from source, using the
bootstrap only as the seed environment. In particular, musl, binutils, and GCC
are normal packages rather than permanent parts of the seed.

The package tree uses a root-prefix filesystem layout. Executables, libraries,
headers, and architecture-independent data are installed in `/bin`, `/lib`,
`/include`, and `/share`. The `root-layout` package supplies the filesystem
skeleton and compatibility links `/usr -> .` and `/sbin -> bin`. The original
bootstrap archive remains unchanged; `bootstrap-tools` normalizes it into this
layout before it is used by regular builds.

Packages also apply this tree's build-environment policy explicitly, overriding
the default `PATH` with `/bin`. Other trees can use the default environment or
override any value through a package's `buildEnv` object.

Source archives are extracted with `--no-same-owner`. This also permits builds
invoked as root: bubblewrap maps only the build user's UID/GID, so ownership
IDs recorded by upstream release archives need not exist in the sandbox.

Each exported field is a build root. For example, this rebuilds GCC and all of
its prerequisites:

```sh
magpkg build \
  --jobs 1 \
  --parallelism "$(nproc)" \
  core.jsonnet gcc
```

The other roots are `make`, `musl`, `musl_rt`, `binutils`, `coreutils`,
`gawk`, `sed`, `findutils`, `diffutils`, `pkgconfig`, `bash`, `gzip`, `xz`,
`tar`, `grep`, `libgcc_rt`, and `libstdcpp_rt`. Separate build invocations can
share the same store: package locks prevent duplicate publication while an
executor continues with any other ready branch.

## Shell environment

`shell.jsonnet` demonstrates a package-defined development shell. Its runtime
closure supplies the bootstrap tools and an executable launcher at
`/libexec/magpkg-shell`. Magpkg materializes and leases the closure, while the
launcher controls bubblewrap mounts, isolation, and the default interactive
shell:

```sh
magpkg shell shell.jsonnet shell
```

A command after `--` is passed unchanged to the launcher:

```sh
magpkg shell \
  shell.jsonnet shell -- cc --version
```

Package-provided launchers execute on the host with the invoking user's
permissions before creating their sandbox. Only trusted packages and binary
caches should be used for shell environments.

## Wayland desktop

The distro selects its desktop in `magnet-linux/desktop-hyprland.jsonnet`.
[Hyprland](hyprland/README.md) supplies the compositor and Mesa graphics;
[login](login/README.md) supplies greetd and its GTK greeter. Foot, Waybar,
Fuzzel, notifications, audio, and NetworkManager complete the desktop.
Shared musl libraries are defined in `desktop-libs.jsonnet`; native build
tools live in `desktop-tools.jsonnet`. Sources are pinned by SHA-256.

See [the desktop guide](https://github.com/magnet-linux/magnet-linux/blob/main/magnet-linux/DESKTOP.md) for installation,
configuration, and graphical QEMU tests.

The optional [Firefox recipes](firefox/README.md) and
[Chromium recipes](chromium/README.md) live in their own directories.
[browser-common](browser-common/README.md) supplies shared GTK libraries and
native Rust/LLVM build recipes. Browser-specific patches and tools remain
with their browser. Everything installs into the normal global layout.
The desktop roots are `desktop` (no browser), `desktop-browser` (Firefox),
`desktop-chromium`, and `desktop-browsers` (both browsers).
