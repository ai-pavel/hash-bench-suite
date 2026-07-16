# frozen_string_literal: true

# Local pure-Ruby shim providing the top-level `Blake2b` API that
# lib/hashers/blake2b.rb expects, backed by the `digest-blake2b` gem.
# Used only on platforms where the native `blake2b` C extension cannot
# be built (e.g. arm64-darwin with the current Xcode toolchain).
require "digest/blake2b"

class Blake2b
  def self.hex(input, key = Blake2b::Key.none, out_len = 32)
    ::Digest::Blake2b.hex(input, key, out_len)
  end

  def self.bytes(input, key = Blake2b::Key.none, out_len = 32)
    ::Digest::Blake2b.bytes(input, key, out_len)
  end

  class Key < ::Digest::Blake2b::Key; end
end