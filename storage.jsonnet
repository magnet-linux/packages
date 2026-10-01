// Filesystem and UEFI installation tools, independent of distro layout.
local core = import './core.jsonnet';
local base = import './base/tools.jsonnet';
local tools = import './desktop-tools.jsonnet';
local kernelTools = import './kernel-tools.jsonnet';
local b = (import './base/build.libsonnet') {
  sources+: {
    dosfstools: {
      version: '4.2', directory: 'dosfstools-4.2',
      archive: {
        filename: 'dosfstools-4.2.tar.gz',
        sha256: '64926eebf90092dca21b14259a5301b7b98e7b1943e8a201c7d726084809b527',
        urls: ['https://github.com/dosfstools/dosfstools/releases/download/v4.2/dosfstools-4.2.tar.gz'],
      },
    },
    e2fsprogs: {
      version: '1.47.3', directory: 'e2fsprogs-1.47.3',
      archive: {
        filename: 'e2fsprogs-1.47.3.tar.xz',
        sha256: '857e6ef800feaa2bb4578fbc810214be5d3c88b072ea53c5384733a965737329',
        urls: ['https://www.kernel.org/pub/linux/kernel/people/tytso/e2fsprogs/v1.47.3/e2fsprogs-1.47.3.tar.xz'],
      },
    },
    grub: {
      version: '2.14', directory: 'grub-2.14',
      archive: {
        filename: 'grub-2.14.tar.xz',
        sha256: 'bc8d3c73535b8838d8c8e2654d73edc4e6ae8c8acdb45d5df5dc9a1547446d43',
        urls: ['https://mirrors.kernel.org/gnu/grub/grub-2.14.tar.xz',
               'https://ftp.gnu.org/gnu/grub/grub-2.14.tar.xz'],
      },
    },
  },
};
{
  dosfstools: b.autotools('dosfstools', '--enable-compat-symlinks --without-udev', [], [], '', |||
    install -Dm644 COPYING /out/share/licenses/dosfstools/COPYING
  |||),
  e2fsprogs: b.autotools('e2fsprogs',
    '--with-root-prefix= --disable-libuuid --disable-libblkid --disable-uuidd --disable-fsck --disable-e2initrd-helper --disable-nls --disable-fuse2fs --enable-elf-shlibs',
    [base.util_linux], [core.gawk, core.bash], '', |||
      mkdir -p /out/share/e2fsprogs
      if test -f /out/etc/mke2fs.conf; then
        mv /out/etc/mke2fs.conf /out/share/e2fsprogs/mke2fs.conf
      fi
      rm -rf /out/etc
      if test -d /out/sbin; then cp -a /out/sbin/. /out/bin/; rm -rf /out/sbin; fi
      install -Dm644 NOTICE /out/share/licenses/e2fsprogs/NOTICE
  |||),
  grub: b.autotools('grub',
    '--target=x86_64 --with-platform=efi --disable-nls --disable-werror --disable-device-mapper --disable-grub-mkfont --disable-liblzma',
    [base.shell_tools], [core.gcc, core.make, tools.python,
                       kernelTools.bison, kernelTools.flex, kernelTools.m4], |||
      # The release includes headers generated on glibc. Regenerate them
      # using this build's musl configure results.
      for template in grub-core/lib/gnulib/*.in.h; do
        rm -f "${template%.in.h}.h"
      done
    |||, |||
      rm -rf /out/etc
      install -Dm644 COPYING /out/share/licenses/grub/COPYING
  |||),
}
