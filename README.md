# Homebrew tap for maintained ext4fuse

Experimental read-only [ulf16/ext4fuse](https://github.com/ulf16/ext4fuse), packaged
from a pinned source commit with a SHA-256 archive checksum. Builds locally;
there are no prebuilt bottles. Requires macOS Sequoia or newer and macFUSE's FUSE 3
development files. Validated on Intel Sequoia; Apple Silicon remains untested.

## Install

If macFUSE is already installed with FUSE 3 development files, keep that installation.
Otherwise install it and follow its normal macOS approval process:

```sh
brew install --cask macfuse
```

Then install and test this package:

```sh
brew install ulf16/ext4fuse/ext4fuse-maintained
brew test ulf16/ext4fuse/ext4fuse-maintained
```

The command is `ext4fuse-maintained`. This package can coexist with Homebrew's old
`ext4fuse`; it does not replace that executable, change PATH, or remove FUSE software.

## Use

Unmount the ext4 partition first. Replace both placeholders with real paths:

```sh
ext4fuse-maintained /dev/diskNsM /path/to/mountpoint -s -o ro,default_permissions
```

This enforces the reported numeric Linux UID/GID and mode bits. Foreign Linux private
files may therefore be inaccessible to your macOS account. For deliberate recovery,
`defer_permissions` bypasses kernel mode checks; the reader does not enforce them itself.
Keep recovery mounts private. Linux ACLs are not implemented.

Unmount using `umount /path/to/mountpoint`. Raw-device access can require `sudo`.
The reader rejects unsupported ext4 layouts and filesystems needing journal replay.
See the [reader documentation](https://github.com/ulf16/ext4fuse#readme) for feature
limits and disposable-image tests. The formula test checks checksum rejection without
mounting; successful installation does not verify macFUSE approval or a real disk.

## Upgrade or remove

```sh
brew update
brew upgrade ulf16/ext4fuse/ext4fuse-maintained
brew uninstall ulf16/ext4fuse/ext4fuse-maintained
```

Uninstalling this package does not uninstall macFUSE or the older ext4fuse.

## Packaging validation

Version 0.2.0 was built from source and installed with Homebrew on Intel macOS
15.8.1 using macFUSE 5.4.0. `brew test`, formula audit, and style checks pass.
The installed executable also passed a disposable-image macFUSE mount test:
exact contents, a 255-byte filename, missing-path handling, and write rejection.
The original `/usr/local/bin/ext4fuse` remained unchanged.

Version 0.2.1 preserves full Linux UID/GID values and reports inode numbers. Its
installed command passes hidden-directory, repeated-missing-path and colon-filename
regressions, plus permission tests with both `default_permissions` and
`defer_permissions`. `brew test`, audit and style checks pass. The private recovery
mode bypasses permission bits; strict mode denies foreign private files and blocked
file/directory access. Cross-user access and Linux ACL equivalence are not certified.

Version 0.2.2 corrects huge-file allocation counts, rejects unrepresentable stat sizes,
and includes large sparse-file/legacy-indirect/deep-extent regression coverage. It uses
validated sparse gap lengths and table-based CRC32C. The reader's allocation callback
matches debugfs, but macFUSE 5.4.0 derives mounted stat/du allocation from logical size
([upstream issue #1121](https://github.com/macfuse/macfuse/issues/1121)). This provider
limitation remains; sparse-copy tests explicitly skip zero chunks.

The installed 0.2.2 package passes `brew test`, formula audit/style checks, and the
mounted path/ownership/strict-permission smoke test on Intel Sequoia. The source's
89 large-file checks pass with sanitizers for both FUSE APIs; Linux CI covers them
alongside checksum, corruption, ownership and normal-image regressions.

Version 0.2.3 preserves high physical address words for extent data, external extent
nodes and inode tables, plus the 64-bit filesystem block count. It also reads Linux
inline files and both inline-directory regions using bounded inode-body attributes.
Descriptor memory limits and rejection of meta_bg/other unsupported layouts remain.
No journal replay, write support, Linux ACLs or macFUSE stat/du allocation fix is added.

Both FUSE APIs pass all portable suites with sanitizers, including 817 inline checks
and optional high-address fixtures using real 16 TiB sparse geometry with explicit
metadata/data relocations. Linux CI passes for both APIs. Installed 0.2.3 passes
Homebrew test/audit/style checks, mounted inline reads and directory listing, symlinks,
write rejection, and the existing strict-permission/path regressions on Intel Sequoia.

Version 0.2.4 corrects signed and extended timestamp seconds, preserves nanoseconds,
and exposes stored creation time as macOS birthtime. It also accepts meta_bg layouts
with checked distributed primary descriptors, sparse-super variants and mixed early
classic placement. Descriptor checksums, inode bounds and resource limits remain.

Both FUSE APIs pass the full sanitizer suites, including 53 timestamp and 108 meta_bg
checks; Linux CI passes for both. Installed 0.2.4 passes Homebrew test/audit/style checks
and mounted native-stat verification of exact seconds/nanoseconds for all four time
fields, combined meta_bg/inline contents, and strict path/permission regressions.
Read-only access, no journal replay, unexposed Linux ACLs and the macFUSE sparse stat/du
allocation limitation remain.

Version 0.2.5 adds read-only extended-attribute listing and retrieval for inode-body
and external-block storage. Binary and empty values retain their Linux namespace
names; internal system.data is hidden. Ext4 POSIX ACLs are converted to Linux userspace
xattr encoding and exposed as metadata. Linux ACL/capability/SELinux enforcement,
Finder namespace translation and ea_inode-backed large values are not added.

Both FUSE APIs pass all portable sanitizer suites, including 1,285 new xattr checks
across block/inode sizes and checksum variants, debugfs comparisons, API size/error
behavior and malformed metadata with repaired checksums. Linux CI passes for both APIs.
Installed 0.2.5 passes Homebrew test/audit/style and mounted native xattr retrieval,
symlink attributes, binary/empty values, write rejection, exact timestamp/meta_bg/inline
verification and strict path/permission regressions on Intel Sequoia/macFUSE 5.4.0.

Version 0.2.6 adds validated read-only `ea_inode` values up to 64 KiB, including
shared values and attributes on inline files. It verifies EA inode state, references,
metadata checksums, value hashes and complete payloads; internal EA inodes cannot
be opened through directory entries. Legacy unhashed Lustre EA layouts remain
unsupported. Read-only access and the existing ACL enforcement and sparse allocation
limitations remain.

Both FUSE APIs pass 1,012 EA checks with sanitizers and the existing portable suites.
Linux CI passes for both APIs. Homebrew test, strict audit and style checks pass.
Installed 0.2.6 passes mounted 64 KiB binary retrieval, empty and symlink attributes,
Linux ACL metadata, write rejection and timestamp/path regressions on Intel Sequoia.
