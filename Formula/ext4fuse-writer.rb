class Macfuse3Requirement < Requirement
  fatal true

  satisfy(build_env: false) do
    File.exist?("/usr/local/include/fuse3/fuse.h") &&
      File.exist?("/usr/local/lib/libfuse3.dylib") &&
      File.exist?("/usr/local/lib/pkgconfig/fuse3.pc")
  end

  def message
    <<~EOS
      macFUSE with FUSE 3 development files is required.
      Install it with: brew install --cask macfuse
      Complete macFUSE's normal macOS approval process before mounting.
    EOS
  end
end

class Ext4fuseWriter < Formula
  desc "Managed ext4 write mounts with explicit transaction recovery"
  homepage "https://github.com/ulf16/ext4fuse"
  url "https://github.com/ulf16/ext4fuse/archive/dfcd316dfdf1aef546e323a0aa0c4e5ba854941e.tar.gz"
  version "0.3.0-beta.2"
  sha256 "9e1a78137c6fe1acff02660a8bcbbf110a58cfa3bfbb80a757161053ee8cec63"
  license "GPL-2.0-only"

  env :std

  depends_on "pkgconf" => :build
  depends_on "e2fsprogs"
  depends_on Macfuse3Requirement
  depends_on macos: :sequoia
  depends_on "python@3.14"

  def install
    ENV.prepend_path "PKG_CONFIG_PATH", "/usr/local/lib/pkgconfig"
    ENV.prepend_path "PKG_CONFIG_PATH", formula_opt_lib("e2fsprogs")/"pkgconfig"
    python = formula_opt_bin("python@3.14")/"python3.14"
    system python, "experimental/shared-writer/build.py", "--runtime-only", "--work", "writer-build"
    system python, "experimental/shared-writer/install.py", "--prefix", prefix,
           "--build-dir", "writer-build", "--python", python,
           "--tools-dir", Formula["e2fsprogs"].opt_sbin, "--version", version
  end

  def caveats
    <<~EOS
      Use ext4fuse-writer; the read-only ext4fuse-maintained command is unchanged.
      The write engine remains experimental; physical power-loss certification is pending.
      Start with a copied image:
        ext4fuse-writer init --image /path/to/linux.img /path/to/new-state
        ext4fuse-writer mount /path/to/new-state /path/to/empty-mountpoint
      From another terminal:
        ext4fuse-writer unmount /path/to/new-state
      After interruption, detach any stale mount and run ext4fuse-writer recover STATE.
      Device mode requires an explicitly selected offline partition and off-device state.
      Preserve the entire state directory until device recovery and clean unmount finish.
      See #{share}/doc/ext4fuse-writer/WORKFLOW.md for the complete workflow and limits.
    EOS
  end

  test do
    command = bin/"ext4fuse-writer"
    assert_match version.to_s, shell_output("#{command} --version")
    assert_match "e2fsck", shell_output("#{command} doctor")
    image = testpath/"source.img"
    image.open("wb") { |file| file.truncate(32 * 1024 * 1024) }
    system Formula["e2fsprogs"].opt_sbin/"mke2fs", "-q", "-F", "-t", "ext4", "-b", "4096", image
    before = Digest::SHA256.file(image).hexdigest
    state = testpath/"state"
    system command, "init", "--image", image, state
    assert_equal before, Digest::SHA256.file(image).hexdigest
    assert_equal before, Digest::SHA256.file(state/"chain/image.img").hexdigest
    status = JSON.parse(shell_output("#{command} status #{state} --json"))
    assert_equal "ready", status.fetch("phase")
    assert_equal false, status.fetch("busy")
    system command, "recover", state
    system Formula["e2fsprogs"].opt_sbin/"e2fsck", "-fn", state/"chain/image.img"
  end
end
