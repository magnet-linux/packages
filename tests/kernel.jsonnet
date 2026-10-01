// Exercise the configurable kernel recipe without any distribution checkout.
{ kernel: (import '../linux.libsonnet').kernel('CONFIG_64BIT=y\n', 'kernel-test') }
