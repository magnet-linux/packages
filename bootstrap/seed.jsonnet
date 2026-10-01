// Populate a store's content-addressed source cache from a local seed archive.
local seed = (import '../bootstrap.jsonnet').bootstrap_seed;
{
  seed: seed + {
    name: 'local-bootstrap-source',
    fetch: [seed.fetch[0] + { urls: [std.extVar('bootstrap-url')] }],
  },
}
