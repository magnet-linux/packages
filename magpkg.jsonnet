local bootstrap = (import './bootstrap.jsonnet').bootstrap;
local go = (import './go.jsonnet').go;
local shell_tools = (import './base/tools.jsonnet').shell_tools;
local bubblewrap = (import './bubblewrap.jsonnet').bubblewrap;
local ca_certificates = (import './ca-certificates.jsonnet').ca_certificates;
local modules = import './magpkg-modules.libsonnet';
local version = 'v0.1.0';

local moduleFetches = std.flattenArrays([
  [{
    filename: 'module-%d.%s' % [i, ext],
    sha256: modules[i].sha256[ext],
    urls: ['https://proxy.golang.org/%s/@v/%s.%s' % [modules[i].path, modules[i].version, ext]],
  } for ext in ['mod', 'zip']]
  for i in std.range(0, std.length(modules) - 1)
]);

// Materialize a local Go module proxy from magpkg's verified fetches. Nothing
// needs network access inside the build sandbox; go.sum still checks contents.
local prepareModules = std.join('\n', [
  |||
    mkdir -p /build/proxy/%(path)s/@v
    cp /fetch/module-%(index)d.mod /build/proxy/%(path)s/@v/%(version)s.mod
    cp /fetch/module-%(index)d.zip /build/proxy/%(path)s/@v/%(version)s.zip
    echo '{"Version":"%(version)s"}' > /build/proxy/%(path)s/@v/%(version)s.info
  ||| % { path: modules[i].path, version: modules[i].version, index: i }
  for i in std.range(0, std.length(modules) - 1)
]);

{
  magpkg: {
    name: 'magpkg-' + version,
    buildEnv: {
      PATH: '/bin',
      CGO_ENABLED: '0',
      GOTOOLCHAIN: 'local',
      GOPROXY: 'file:///build/proxy',
      GOSUMDB: 'off',
      GOCACHE: '/build/go-cache',
      GOMODCACHE: '/build/go-modules',
      // Go normally makes extracted modules read-only, preventing the store's
      // unprivileged build-workspace cleanup from removing their contents.
      GOFLAGS: '-modcacherw',
    },
    build: { kind: 'script', script: prepareModules + '\n' + |||
      tar --no-same-owner -xzf /fetch/magpkg.tar.gz
      cd magpkg-v0.1.0
      mkdir -p /out/bin
      go test -p "$BUILD_PARALLELISM" -mod=readonly ./...
      go build -p "$BUILD_PARALLELISM" -mod=readonly -trimpath -buildvcs=false \
        -ldflags='-s -w -X main.version=v0.1.0' -o /out/bin/magpkg ./cmd/magpkg
      /out/bin/magpkg --help
    ||| },
    buildDeps: [bootstrap, go],
    runDeps: [shell_tools, bubblewrap, ca_certificates],
    fetch: [{
      filename: 'magpkg.tar.gz',
      // Uploaded source release asset: exact published bytes, pinned by hash.
      sha256: 'b8b0d8102874a5833f5e7d60ea1e587643bcc4762cc1508140530b51a7359e3a',
      urls: ['https://github.com/magnet-linux/magpkg/releases/download/' + version + '/magpkg-' + version + '.tar.gz'],
    }] + moduleFetches,
  },
}
