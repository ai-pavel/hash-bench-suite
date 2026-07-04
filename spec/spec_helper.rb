require 'simplecov'
require 'simplecov-cobertura'
SimpleCov.start do
  formatter SimpleCov::Formatter::CoberturaFormatter
end

# frozen_string_literal: true

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
