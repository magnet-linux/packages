local b = (import './browser-common/build.libsonnet') {
  sources+: import './notifications-sources.libsonnet',
};
local l = import './desktop-libs.jsonnet';
local common = import './browser-common/libraries.jsonnet';
local basu = b.meson('basu', '-Daudit=disabled -Dlibcap=disabled', [],
  [(import './desktop-tools.jsonnet').gperf], |||
    # Build-sandbox accounts do not describe the installed system. Keep the
    # explicit upstream nobody default and skip probing the builder's passwd.
    sed -i 's/if not meson.is_cross_build()/if false/' meson.build
  |||, |||
  install -Dm644 LICENSE.LGPL2.1 /out/share/licenses/basu/LICENSE.LGPL2.1
|||);
local libnotify = b.meson('libnotify',
  '-Dtests=false -Dintrospection=disabled -Dman=false -Dgtk_doc=false -Ddocbook_docs=disabled',
  [l.glib, common.pixbuf], [], '', |||
    install -Dm644 COPYING /out/share/licenses/libnotify/COPYING
  |||);
local makeMako(after) = b.meson('mako', '-Dsd-bus-provider=basu -Dicons=enabled -Dman-pages=disabled',
  [l.wayland, l.pango, l.cairo, common.pixbuf, basu, common.dbus], [l.protocols], '', |||
    install -Dm644 LICENSE /out/share/licenses/mako/LICENSE
    mkdir -p /out/share/doc/mako
    cp doc/*.scd /out/share/doc/mako/

  ||| + after);
local mako = makeMako('');
{
  makoWithPostInstall:: makeMako,
  basu: basu,
  libnotify: libnotify,
  mako: mako,
  notifications: {
    name: 'magnet-notifications', build: { kind: 'none' },
    buildDeps: [], fetch: [], runDeps: [mako, libnotify],
  },
}
