# frozen_string_literal: true

module HashBenchmarkSuite
  module Hashers
    # Abstract base class defining the unified Hasher interface.
    # All hasher adapters must implement #digest(data) -> hex string.
    class Base
      # Returns the human-readable name of the hash algorithm.
      def name
        raise NotImplementedError, "#{self.class}#name must be implemented"
      end

      # Computes the hash digest of +data+ (a binary string).
      # Returns the digest as a lowercase hex-encoded string.
      def digest(data)
        raise NotImplementedError, "#{self.class}#digest must be implemented"
      end

      # Returns the output length of the digest in bytes.
      def digest_length
        raise NotImplementedError, "#{self.class}#digest_length must be implemented"
      end
    end
  end
end
