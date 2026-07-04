# frozen_string_literal: true

require "spec_helper"

RSpec.describe HashBenchmarkSuite::Hashers::Blake2b do
  subject(:hasher) { described_class.new }

  describe "#name" do
    it "returns Blake2b-256" do
      expect(hasher.name).to eq("Blake2b-256")
    end
  end

  describe "#digest_length" do
    it "returns 32 bytes" do
      expect(hasher.digest_length).to eq(32)
    end
  end

  describe "#digest" do
    # Blake2b-256 test vectors (unkeyed, 32-byte output)
    it "hashes empty string correctly" do
      # Blake2b-256("") — well-known test vector
      expected = "0e5751c9933e39f97817d7e1f12b5f1e5b8141c0e8208e008e5f1b35d9ad8e33"
      # Note: blake2b gem may return uppercase; normalize
      expect(hasher.digest("").downcase).to eq(expected)
    end

    it "returns a 64-character hex string" do
      result = hasher.digest("test")
      expect(result.downcase).to match(/\A[0-9a-f]{64}\z/)
    end

    it "is deterministic" do
      data = "deterministic test"
      expect(hasher.digest(data)).to eq(hasher.digest(data))
    end

    it "produces different hashes for different inputs" do
      expect(hasher.digest("foo")).not_to eq(hasher.digest("bar"))
    end
  end
end
