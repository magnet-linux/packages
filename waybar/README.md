# Waybar

`waybar.jsonnet` builds Waybar 0.15.0 for the Hyprland desktop. The dependencies
reuse the shared GTK, Wayland, font and graphics packages. New libraries live
in `dependencies.jsonnet`: GTK's C++ bindings, fmt, spdlog, jsoncpp,
gtk-layer-shell, and an xkbregistry supplement to the existing libxkbcommon.
All upstream archives are pinned by SHA-256 and builds run without network
access. The clock uses GCC's standard C++ timezone support and the source-built
IANA database from `packages/tzdata.jsonnet`.
The default clock explicitly uses the `C` locale: the musl toolchain's generic
C++ locale implementation does not accept the desktop's `C.UTF-8` locale name.

`hyprland-lua.patch` adapts the release's workspace click commands to the Lua
dispatcher API used by our pinned Hyprland 0.56.2. It quotes workspace names
before putting them in Lua expressions. This package targets that API; it is
not intended for older Hyprland versions. See upstream's corresponding
[IPC change](https://github.com/Alexays/Waybar/commit/05945748dccce28bf96d26d8f64a9e69a8dd49ba).

PulseAudio volume support connects to pipewire-pulse. Network and PulseAudio support are enabled. Optional tray, Bluetooth and
systemd integrations are disabled. The distro configures Hyprland workspaces,
window title, network, output volume and clock. No Sway runtime is required.

```sh
magpkg build --store _work/store --jobs 3 --parallelism 8 waybar/waybar.jsonnet waybar
```

`setup-login.sh` provisions `/etc/xdg/waybar/config.jsonc` and `style.css` only
when absent. User files in `~/.config/waybar/` take precedence. Hyprland starts
Waybar once on session startup; logging out terminates it with the session.
Its log is `~/.local/state/magnet-linux/waybar.log` (under `$XDG_STATE_HOME`
instead when set).
See [DESKTOP.md](https://github.com/magnet-linux/magnet-linux/blob/main/magnet-linux/DESKTOP.md) for installation and the real
QEMU test, including clicking a workspace button and checking reserved space.
