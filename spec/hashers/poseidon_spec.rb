# frozen_string_literal: true

require "spec_helper"

RSpec.describe HashBenchmarkSuite::Hashers::Poseidon do
  subject(:hasher) { described_class.new }

  describe "#name" do
    it "returns Poseidon-BN128" do
      expect(hasher.name).to eq("Poseidon-BN128")
    end
  end

  describe "#digest_length" do
    it "returns 32 bytes" do
      expect(hasher.digest_length).to eq(32)
    end
  end

  describe "#digest" do
    it "returns a 64-character hex string for empty input" do
      result = hasher.digest("")
      expect(result).to match(/\A[0-9a-f]{64}\z/)
    end

    it "returns a 64-character hex string for non-empty input" do
      result = hasher.digest("hello")
      expect(result).to match(/\A[0-9a-f]{64}\z/)
    end

    it "is deterministic" do
      data = "deterministic test"
      expect(hasher.digest(data)).to eq(hasher.digest(data))
    end

    it "produces different hashes for different inputs" do
      expect(hasher.digest("foo")).not_to eq(hasher.digest("bar"))
    end

    it "produces a result within the BN128 field" do
      result_int = hasher.digest("test").to_i(16)
      expect(result_int).to be < HashBenchmarkSuite::Hashers::Poseidon::FIELD_PRIME
      expect(result_int).to be >= 0
    end

    it "handles binary data" do
      binary = (0..255).map(&:chr).join
      result = hasher.digest(binary)
      expect(result).to match(/\A[0-9a-f]{64}\z/)
    end

    it "produces consistent results across multiple calls" do
      data = "consistency check"
      results = 5.times.map { hasher.digest(data) }
      expect(results.uniq.size).to eq(1)
    end
  end
end
