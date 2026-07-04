# frozen_string_literal: true

require "spec_helper"

RSpec.describe HashBenchmarkSuite::Hashers::Base do
  subject(:hasher) { described_class.new }

  describe "#name" do
    it "raises NotImplementedError" do
      expect { hasher.name }.to raise_error(NotImplementedError)
    end
  end

  describe "#digest" do
    it "raises NotImplementedError" do
      expect { hasher.digest("data") }.to raise_error(NotImplementedError)
    end
  end

  describe "#digest_length" do
    it "raises NotImplementedError" do
      expect { hasher.digest_length }.to raise_error(NotImplementedError)
    end
  end
end
