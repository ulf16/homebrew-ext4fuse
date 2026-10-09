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

class Ext4fuseMaintained < Formula
  desc "Read-only ext4 filesystem reader with metadata validation"
  homepage "https://github.com/ulf16/ext4fuse"
  url "https://github.com/ulf16/ext4fuse/archive/46882ce995840a70fba05f591dc4399d72111645.tar.gz"
  version "0.2.4"
  sha256 "af6c90f405419d822fa68f94754dedc670659bd806016dffa325d21002246f88"
  license "GPL-2.0-only"

  # macFUSE installs its development files outside Homebrew's managed prefix.
  env :std

  depends_on "pkgconf" => :build
  depends_on "e2fsprogs" => :test
  depends_on Macfuse3Requirement
  depends_on macos: :sequoia

  def install
    ENV.prepend_path "PKG_CONFIG_PATH", "/usr/local/lib/pkgconfig"
    system "make", "FUSE_API=3", "VERSION=#{version}", "MACOSX_DEPLOYMENT_TARGET=15.0"
    bin.install "ext4fuse" => "ext4fuse-maintained"
    doc.install "README.md", "VALIDATION.md", "COPYING"
  end

  def caveats
    <<~EOS
      Use ext4fuse-maintained to run this fork; existing ext4fuse commands are unchanged.
      This is an experimental read-only reader. Unmount ext4 volumes before use.
      Mount with: ext4fuse-maintained /dev/diskNsM /path/to/mountpoint -s -o ro,default_permissions
      Linux UID/GID values are preserved. Recovery option defer_permissions bypasses mode checks.
      macFUSE must be installed and approved for mounts to work.
      macFUSE may report logical allocation for sparse files in mounted stat/du output.
      Validated on Intel macOS Sequoia; Apple Silicon is not yet tested.
    EOS
  end

  test do
    assert_match "Version: #{version}", shell_output("#{bin}/ext4fuse-maintained 2>&1", 1)
    image = testpath/"fixture.img"
    image.open("wb") { |file| file.truncate(16 * 1024 * 1024) }
    system Formula["e2fsprogs"].opt_sbin/"mke2fs", "-q", "-F", "-t", "ext4", "-b", "4096", image
    # Corrupt only a volume-name byte; preflight must reject it before FUSE starts.
    image.open("r+b") do |file|
      file.seek(1024 + 0x78)
      byte = file.read(1).unpack1("C")
      file.seek(1024 + 0x78)
      file.write([byte ^ 1].pack("C"))
    end
    before = image.read
    output = shell_output("#{bin}/ext4fuse-maintained #{image} #{testpath}/unused 2>&1", 1)
    assert_match "superblock checksum mismatch", output
    assert_equal before, image.read
  end
end
