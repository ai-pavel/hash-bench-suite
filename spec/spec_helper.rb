require 'simplecov'
require 'simplecov-cobertura'
SimpleCov.start do
  formatter SimpleCov::Formatter::CoberturaFormatter
  skip "/vendor/"
end

# frozen_string_literal: true

# On platforms where the native `blake2b` C extension cannot be built
# (e.g. arm64-darwin with the current Xcode toolchain), fall back to a
# pure-Ruby shim backed by the `digest-blake2b` gem. CI (ubuntu x86_64)
# uses the real native `blake2b` gem via bundler and skips this fallback.
unless Gem::Specification.find_all_by_name("blake2b").any?
  shim_lib = File.expand_path("../vendor/blake2b_shim/lib", __dir__)
  $LOAD_PATH.unshift(shim_lib)
end

require "bundler/setup"
require_relative "../lib/hashers/sha256"
require_relative "../lib/hashers/blake2b"
require_relative "../lib/hashers/keccak256"
require_relative "../lib/hashers/poseidon"
require_relative "../lib/benchmark_runner"

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.order = :random
  Kernel.srand config.seed
end
