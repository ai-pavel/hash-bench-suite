# frozen_string_literal: true

require "spec_helper"

RSpec.describe HashBenchmarkSuite::Hashers::SHA256 do
  subject(:hasher) { described_class.new }

  describe "#name" do
    it "returns SHA-256" do
      expect(hasher.name).to eq("SHA-256")
    end
  end

  describe "#digest_length" do
    it "returns 32 bytes" do
      expect(hasher.digest_length).to eq(32)
    end
  end

  describe "#digest" do
    # NIST test vectors for SHA-256
    it "hashes empty string correctly" do
      expect(hasher.digest("")).to eq(
        "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
      )
    end

    it "hashes 'abc' correctly" do
      expect(hasher.digest("abc")).to eq(
        "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
      )
    end

    it "hashes 'hello world' correctly" do
      expect(hasher.digest("hello world")).to eq(
        "b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9"
      )
    end

    it "returns a 64-character hex string" do
      result = hasher.digest("test")
      expect(result).to match(/\A[0-9a-f]{64}\z/)
    end

    it "is deterministic" do
      data = "deterministic test"
      expect(hasher.digest(data)).to eq(hasher.digest(data))
    end
  end
end
