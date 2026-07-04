# frozen_string_literal: true

require "digest/sha3"
require_relative "base"

module HashBenchmarkSuite
  module Hashers
    class Keccak256 < Base
      def name
        "Keccak-256"
      end

      def digest(data)
        ::Digest::SHA3.hexdigest(data, 256)
      end

      def digest_length
        32
      end
    end
  end
end
