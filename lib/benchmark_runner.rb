# frozen_string_literal: true

require "benchmark/ips"
require "json"
require "objspace"

require_relative "hashers/sha256"
require_relative "hashers/blake2b"
require_relative "hashers/keccak256"
require_relative "hashers/poseidon"

module HashBenchmarkSuite
  class BenchmarkRunner
    # Default input sizes: 1 KB, 1 MB, 100 MB
    DEFAULT_SIZES = [1_024, 1_048_576, 104_857_600].freeze

    HASHER_REGISTRY = {
      "sha256"    => Hashers::SHA256,
      "blake2b"   => Hashers::Blake2b,
      "keccak256" => Hashers::Keccak256,
      "poseidon"  => Hashers::Poseidon
    }.freeze

    # Size thresholds for Poseidon: skip sizes above this (pure Ruby is very slow
    # on large inputs). We still run it on 1 KB and record N/A for larger sizes.
    POSEIDON_MAX_SIZE = 1_024

    attr_reader :hashers, :sizes, :results

    # @param hasher_names [Array<String>] keys from HASHER_REGISTRY
    # @param sizes [Array<Integer>] input sizes in bytes
    def initialize(hasher_names: HASHER_REGISTRY.keys, sizes: DEFAULT_SIZES)
      @hashers = hasher_names.map do |name|
        key = name.downcase.strip
        klass = HASHER_REGISTRY[key]
        raise ArgumentError, "Unknown hasher: #{name}. Available: #{HASHER_REGISTRY.keys.join(', ')}" unless klass
        klass.new
      end
      @sizes = sizes
      @results = []
    end

    # Run all benchmarks and collect results.
    def run!
      @results = []

      hashers.each do |hasher|
        sizes.each do |size|
          if hasher.is_a?(Hashers::Poseidon) && size > POSEIDON_MAX_SIZE
            @results << {
              hasher: hasher.name,
              input_size: size,
              input_label: human_size(size),
              throughput_mbps: nil,
              latency_ns_per_op: nil,
              memory_bytes: nil,
              skipped: true,
              skip_reason: "Poseidon pure-Ruby too slow for #{human_size(size)} inputs"
            }
            next
          end

          result = benchmark_hasher(hasher, size)
          @results << result
        end
      end

      @results
    end

    # Format results as an ASCII table string.
    def to_ascii_table
      return "No results. Run benchmarks first." if results.empty?

      col_widths = {
        hasher:     results.map { |r| r[:hasher].length }.max,
        size:       results.map { |r| r[:input_label].length }.max,
        throughput: 16,
        latency:    16,
        memory:     14
      }
      col_widths[:hasher] = [col_widths[:hasher], 10].max
      col_widths[:size]   = [col_widths[:size], 10].max

      header = format(
        "| %-*s | %-*s | %-*s | %-*s | %-*s |",
        col_widths[:hasher],     "Hasher",
        col_widths[:size],       "Input Size",
        col_widths[:throughput], "Throughput MB/s",
        col_widths[:latency],    "Latency ns/op",
        col_widths[:memory],     "Memory Bytes"
      )

      separator = "+" + "-" * (col_widths[:hasher] + 2) +
                  "+" + "-" * (col_widths[:size] + 2) +
                  "+" + "-" * (col_widths[:throughput] + 2) +
                  "+" + "-" * (col_widths[:latency] + 2) +
                  "+" + "-" * (col_widths[:memory] + 2) + "+"

      lines = [separator, header, separator]

      results.each do |r|
        if r[:skipped]
          throughput_str = "N/A (skipped)"
          latency_str    = "N/A (skipped)"
          memory_str     = "N/A"
        else
          throughput_str = format("%.2f", r[:throughput_mbps])
          latency_str    = format("%.0f", r[:latency_ns_per_op])
          memory_str     = r[:memory_bytes].to_s
        end

        lines << format(
          "| %-*s | %-*s | %*s | %*s | %*s |",
          col_widths[:hasher],     r[:hasher],
          col_widths[:size],       r[:input_label],
          col_widths[:throughput], throughput_str,
          col_widths[:latency],    latency_str,
          col_widths[:memory],     memory_str
        )
      end

      lines << separator
      lines.join("\n")
    end

    # Return results as a JSON string.
    def to_json
      JSON.pretty_generate(
        benchmark_suite: "hash-benchmark-suite",
        timestamp: Time.now.utc.iso8601,
        results: results
      )
    end

    private

    # Run benchmark-ips for a single hasher at a given input size,
    # then measure memory allocation separately.
    def benchmark_hasher(hasher, size)
      data = Random.bytes(size)

      # Warm up and verify the hasher works
      hasher.digest(data)

      # Measure iterations per second with benchmark-ips
      ips_result = nil
      report = Benchmark::IPS::Job.new
      report.config(time: 2, warmup: 1, quiet: true)
      report.report(hasher.name) { hasher.digest(data) }
      report.run

      entry = report.full_report.entries.first
      iterations_per_second = entry.ips

      # Calculate throughput and latency
      throughput_mbps = (iterations_per_second * size) / (1024.0 * 1024.0)
      latency_ns = (1.0 / iterations_per_second) * 1_000_000_000

      # Measure memory allocation for a single call
      memory_bytes = measure_memory { hasher.digest(data) }

      {
        hasher: hasher.name,
        input_size: size,
        input_label: human_size(size),
        throughput_mbps: throughput_mbps.round(2),
        latency_ns_per_op: latency_ns.round(0).to_f,
        memory_bytes: memory_bytes,
        skipped: false
      }
    end

    # Measure memory allocated during a block execution.
    def measure_memory(&block)
      GC.start
      GC.disable
      before = GC.stat[:total_allocated_objects]
      block.call
      after = GC.stat[:total_allocated_objects]
      GC.enable
      (after - before) * 40 # approximate bytes per object (Ruby typical)
    rescue StandardError
      GC.enable
      nil
    end

    def human_size(bytes)
      case bytes
      when 0...1_024 then "#{bytes} B"
      when 1_024...1_048_576 then "#{bytes / 1_024} KB"
      when 1_048_576...1_073_741_824 then "#{bytes / 1_048_576} MB"
      else "#{bytes / 1_073_741_824} GB"
      end
    end
  end
end
