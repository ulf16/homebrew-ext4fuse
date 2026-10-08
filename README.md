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
