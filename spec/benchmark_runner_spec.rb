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

    it "accepts multiple specific hashers" do
      runner = described_class.new(hasher_names: ["sha256", "blake2b"], sizes: [64])
      expect(runner.hashers.map(&:name)).to eq(["SHA-256", "Blake2b-256"])
    end

    it "raises for unknown hashers" do
      expect {
        described_class.new(hasher_names: ["unknown"])
      }.to raise_error(ArgumentError, /Unknown hasher/)
    end

    it "uses default sizes when none specified" do
      runner = described_class.new(hasher_names: ["sha256"])
      expect(runner.sizes).to eq([1_024, 1_048_576, 104_857_600])
    end

    it "accepts custom sizes" do
      runner = described_class.new(hasher_names: ["sha256"], sizes: [32, 128])
      expect(runner.sizes).to eq([32, 128])
    end

    it "starts with empty results" do
      runner = described_class.new(sizes: [64])
      expect(runner.results).to eq([])
    end
  end

  describe "#run!" do
    it "populates results for each hasher-size combination" do
      runner = described_class.new(hasher_names: ["sha256", "blake2b"], sizes: [64])
      runner.run!
      expect(runner.results.length).to eq(2)
      expect(runner.results.map { |r| r[:hasher] }).to contain_exactly("SHA-256", "Blake2b-256")
    end

    it "records throughput and latency" do
      runner = described_class.new(hasher_names: ["sha256"], sizes: [64])
      runner.run!
      result = runner.results.first
      expect(result[:throughput_mbps]).to be_a(Float)
      expect(result[:throughput_mbps]).to be > 0
      expect(result[:latency_ns_per_op]).to be_a(Float)
      expect(result[:latency_ns_per_op]).to be > 0
    end

    it "includes input size metadata" do
      runner = described_class.new(hasher_names: ["sha256"], sizes: [1024])
      runner.run!
      result = runner.results.first
      expect(result[:input_size]).to eq(1024)
      expect(result[:input_label]).to eq("1 KB")
      expect(result[:skipped]).to eq(false)
    end

    it "skips Poseidon for inputs larger than 1 KB" do
      runner = described_class.new(hasher_names: ["poseidon"], sizes: [64, 2048])
      runner.run!
      normal = runner.results.find { |r| r[:input_size] == 64 }
      skipped = runner.results.find { |r| r[:input_size] == 2048 }

      expect(normal[:skipped]).to eq(false)
      expect(skipped[:skipped]).to eq(true)
      expect(skipped[:throughput_mbps]).to be_nil
      expect(skipped[:skip_reason]).to include("Poseidon")
    end

    it "returns the results array" do
      runner = described_class.new(hasher_names: ["sha256"], sizes: [64])
      result = runner.run!
      expect(result).to eq(runner.results)
    end
  end

  describe "#to_ascii_table" do
    it "returns a message when no results exist" do
      runner = described_class.new(sizes: [64])
      expect(runner.to_ascii_table).to include("No results")
    end

    it "returns a formatted table after a run" do
      runner = described_class.new(hasher_names: ["sha256"], sizes: [64])
      runner.run!
      table = runner.to_ascii_table
      expect(table).to include("Hasher")
      expect(table).to include("Input Size")
      expect(table).to include("Throughput MB/s")
      expect(table).to include("Latency ns/op")
      expect(table).to include("Memory Bytes")
      expect(table).to include("SHA-256")
    end

    it "shows N/A for skipped entries" do
      runner = described_class.new(hasher_names: ["poseidon"], sizes: [2048])
      runner.run!
      table = runner.to_ascii_table
      expect(table).to include("N/A (skipped)")
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

    it "includes benchmark suite name and timestamp" do
      runner = described_class.new(hasher_names: ["sha256"], sizes: [64])
      runner.run!
      json = JSON.parse(runner.to_json)
      expect(json["benchmark_suite"]).to eq("hash-benchmark-suite")
      expect(json["timestamp"]).to match(/\d{4}-\d{2}-\d{2}T/)
    end

    it "includes skipped entries in JSON" do
      runner = described_class.new(hasher_names: ["poseidon"], sizes: [64, 2048])
      runner.run!
      json = JSON.parse(runner.to_json)
      skipped = json["results"].find { |r| r["skipped"] == true }
      expect(skipped).not_to be_nil
      expect(skipped["skip_reason"]).to include("Poseidon")
    end
  end
end
