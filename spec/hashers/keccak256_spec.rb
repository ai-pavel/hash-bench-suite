# frozen_string_literal: true

require "spec_helper"

RSpec.describe HashBenchmarkSuite::Hashers::Keccak256 do
  subject(:hasher) { described_class.new }

  describe "#name" do
    it "returns Keccak-256" do
      expect(hasher.name).to eq("Keccak-256")
    end
  end

  describe "#digest_length" do
    it "returns 32 bytes" do
      expect(hasher.digest_length).to eq(32)
    end
  end

  describe "#digest" do
    # Keccak-256 test vectors (note: Keccak-256, NOT SHA3-256)
    it "hashes empty string correctly" do
      # Keccak-256("") — used in Ethereum
      expected = "c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470"
      expect(hasher.digest("")).to eq(expected)
    end

    it "hashes 'testing' correctly" do
      # Well-known Keccak-256 test vector
      expected = "5f16f4c7f149ac4f9510d9cf8cf384038ad348b3bcdc01915f95de12df9d1b02"
      expect(hasher.digest("testing")).to eq(expected)
    end

    it "returns a 64-character hex string" do
      result = hasher.digest("test")
      expect(result).to match(/\A[0-9a-f]{64}\z/)
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
