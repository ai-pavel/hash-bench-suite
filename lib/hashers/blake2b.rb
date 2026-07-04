# frozen_string_literal: true

require "blake2b"
require_relative "base"

module HashBenchmarkSuite
  module Hashers
    class Blake2b < Base
      DIGEST_SIZE = 32 # 256-bit output

      def name
        "Blake2b-256"
      end

      def digest(data)
        key = ::Blake2b::Key.none
        ::Blake2b.hex(data, key, DIGEST_SIZE)
      end

      def digest_length
        DIGEST_SIZE
      end
    end
  end
end
