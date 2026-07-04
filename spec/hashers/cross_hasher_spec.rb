# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Cross-hasher properties" do
  let(:hashers) do
    [
      HashBenchmarkSuite::Hashers::SHA256.new,
      HashBenchmarkSuite::Hashers::Blake2b.new,
      HashBenchmarkSuite::Hashers::Keccak256.new,
      HashBenchmarkSuite::Hashers::Poseidon.new
    ]
  end

  it "all produce 64-character hex strings" do
    hashers.each do |h|
      result = h.digest("test input")
      expect(result.downcase).to match(/\A[0-9a-f]{64}\z/),
        "#{h.name} produced invalid hex: #{result}"
    end
  end

  it "all have 32-byte digest length" do
    hashers.each do |h|
      expect(h.digest_length).to eq(32),
        "#{h.name} has digest_length #{h.digest_length}, expected 32"
    end
  end

  it "all handle empty string input" do
    hashers.each do |h|
      result = h.digest("")
      expect(result.downcase).to match(/\A[0-9a-f]{64}\z/),
        "#{h.name} failed on empty string"
    end
  end

  it "all handle binary data" do
    binary = (0..255).map(&:chr).join
    hashers.each do |h|
      result = h.digest(binary)
      expect(result.downcase).to match(/\A[0-9a-f]{64}\z/),
        "#{h.name} failed on binary data"
    end
  end

  it "all produce different outputs for different inputs" do
    hashers.each do |h|
      a = h.digest("input_a")
      b = h.digest("input_b")
      expect(a).not_to eq(b),
        "#{h.name} produced same hash for different inputs"
    end
  end

  it "each hasher produces unique digests" do
    digests = hashers.map { |h| h.digest("same input") }
    expect(digests.uniq.size).to eq(hashers.size)
  end

  it "all are subclasses of Base" do
    hashers.each do |h|
      expect(h).to be_a(HashBenchmarkSuite::Hashers::Base)
    end
  end
end
