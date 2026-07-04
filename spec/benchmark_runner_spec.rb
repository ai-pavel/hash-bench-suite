# frozen_string_literal: true

require "spec_helper"

RSpec.describe HashBenchmarkSuite::BenchmarkRunner do
  describe "#initialize" do
    it "creates a runner with default hashers" do
      runner = described_class.new(sizes: [64])
      expect(runner.hashers.map(&:name)).to contain_exactly(
        "SHA-256", "Blake2b-256", "Keccak-256", "Poseidon-BN128"
      )
    end

    it "accepts specific hasher names" do
      runner = described_class.new(hasher_names: ["sha256"], sizes: [64])
      expect(runner.hashers.map(&:name)).to eq(["SHA-256"])
    end

    it "raises for unknown hashers" do
      expect {
        described_class.new(hasher_names: ["unknown"])
      }.to raise_error(ArgumentError, /Unknown hasher/)
    end
  end

  describe "#to_ascii_table" do
    it "returns a message when no results exist" do
      runner = described_class.new(sizes: [64])
      expect(runner.to_ascii_table).to include("No results")
    end
  end

  describe "#to_json" do
    it "returns valid JSON after a run" do
      runner = described_class.new(hasher_names: ["sha256"], sizes: [64])
      runner.run!
      json = JSON.parse(runner.to_json)
      expect(json).to have_key("results")
      expect(json["results"].length).to eq(1)
      expect(json["results"].first["hasher"]).to eq("SHA-256")
    end
  end
end
