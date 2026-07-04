# Hash Benchmark Suite

[![CI](https://github.com/pavel-genai/hash-benchmark-suite/actions/workflows/ci.yml/badge.svg)](https://github.com/pavel-genai/hash-benchmark-suite/actions/workflows/ci.yml)

A Ruby benchmarking suite for cryptographic hash functions. Compares throughput, latency, and memory allocation across multiple hash algorithms using inputs of varying sizes.

## Supported Hash Functions

| Algorithm   | Implementation                        |
|-------------|---------------------------------------|
| SHA-256     | Ruby stdlib `OpenSSL::Digest::SHA256` |
| Blake2b     | `blake2b` gem (native extension)      |
| Keccak-256  | `digest-sha3` gem (native extension)  |
| Poseidon    | Pure Ruby over BN128 scalar field     |

## Project Structure

```
lib/
  hashers/
    base.rb          # Abstract Hasher interface
    sha256.rb        # SHA-256 adapter
    blake2b.rb       # Blake2b adapter
    keccak256.rb     # Keccak-256 adapter
    poseidon.rb      # Poseidon hash (pure Ruby, BN128 field)
  benchmark_runner.rb  # Orchestrates benchmarks and formats output
bin/
  run                # CLI entry point
spec/
  hashers/           # RSpec tests with known test vectors
```

## Setup

```bash
bundle install
```

## Running Benchmarks

```bash
bundle exec bin/run
```

Options:

```
--json           Output results as JSON to stdout
--output FILE    Write JSON results to FILE
--sizes SIZES    Comma-separated input sizes in bytes (default: 1024,1048576,104857600)
--hashers LIST   Comma-separated hasher names (default: sha256,blake2b,keccak256,poseidon)
```

Examples:

```bash
# Run all hashers, default sizes, ASCII table output
bundle exec bin/run

# JSON output only
bundle exec bin/run --json

# Specific hashers and sizes
bundle exec bin/run --hashers sha256,blake2b --sizes 1024,1048576

# Save JSON to file
bundle exec bin/run --output results.json
```

## Running Tests

```bash
bundle exec rspec
```

## License

MIT
