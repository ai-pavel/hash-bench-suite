# frozen_string_literal: true

require "openssl"
require_relative "base"

module HashBenchmarkSuite
  module Hashers
    class SHA256 < Base
      def name
        "SHA-256"
      end

      def digest(data)
        OpenSSL::Digest::SHA256.hexdigest(data)
      end

      def digest_length
        32
      end
    end
  end
end
