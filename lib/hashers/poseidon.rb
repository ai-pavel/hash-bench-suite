# frozen_string_literal: true

require_relative "base"

module HashBenchmarkSuite
  module Hashers
    # Pure Ruby Poseidon hash over the BN128 (alt_bn128) scalar field.
    #
    # This is a simplified but correct Poseidon implementation with:
    #   - Width t = 3 (2 inputs + 1 capacity)
    #   - Full rounds R_F = 8, partial rounds R_P = 57
    #   - BN128 scalar field prime
    #
    # Input data is split into 31-byte field elements and absorbed via
    # an overwrite-mode sponge. The first element of the final state is
    # the digest.
    class Poseidon < Base
      # BN128 scalar field order
      FIELD_PRIME = 21_888_242_871_839_275_222_246_405_745_257_275_088_548_364_400_416_034_343_698_204_186_575_808_495_617

      WIDTH       = 3   # t: number of field elements in state
      RATE        = 2   # r: number of elements absorbed per permutation
      FULL_ROUNDS = 8   # R_F
      PARTIAL_ROUNDS = 57 # R_P
      ALPHA       = 5   # S-box exponent: x -> x^5

      def name
        "Poseidon-BN128"
      end

      def digest(data)
        elements = bytes_to_field_elements(data)
        result = poseidon_hash(elements)
        result.to_s(16).rjust(64, "0")
      end

      def digest_length
        32
      end

      private

      # Convert arbitrary bytes into field elements (31 bytes each to stay < p).
      def bytes_to_field_elements(data)
        bytes = data.bytes
        elements = []
        bytes.each_slice(31) do |chunk|
          val = 0
          chunk.each_with_index { |b, i| val |= (b << (8 * i)) }
          elements << (val % FIELD_PRIME)
        end
        elements << 1 if elements.empty? # domain separation for empty input
        elements
      end

      # Sponge construction: absorb all elements, then squeeze one element.
      def poseidon_hash(elements)
        state = Array.new(WIDTH, 0)

        # Absorb phase: overwrite mode
        elements.each_slice(RATE) do |chunk|
          chunk.each_with_index do |el, i|
            state[i] = (state[i] + el) % FIELD_PRIME
          end
          permutation!(state)
        end

        # Squeeze: return first element
        state[0]
      end

      # Poseidon permutation: full rounds, partial rounds, full rounds.
      def permutation!(state)
        round_constants = generate_round_constants
        mds = generate_mds_matrix

        total_rounds = FULL_ROUNDS + PARTIAL_ROUNDS
        half_full = FULL_ROUNDS / 2

        total_rounds.times do |r|
          # AddRoundConstants
          WIDTH.times do |i|
            state[i] = (state[i] + round_constants[r * WIDTH + i]) % FIELD_PRIME
          end

          # SubWords (S-box)
          if r < half_full || r >= half_full + PARTIAL_ROUNDS
            # Full round: apply S-box to all elements
            WIDTH.times do |i|
              state[i] = power_mod(state[i], ALPHA, FIELD_PRIME)
            end
          else
            # Partial round: apply S-box only to first element
            state[0] = power_mod(state[0], ALPHA, FIELD_PRIME)
          end

          # MixLayer (MDS matrix multiplication)
          new_state = Array.new(WIDTH, 0)
          WIDTH.times do |i|
            WIDTH.times do |j|
              new_state[i] = (new_state[i] + mds[i][j] * state[j]) % FIELD_PRIME
            end
          end
          state.replace(new_state)
        end
      end

      # Modular exponentiation using Ruby's built-in Integer#pow(exp, mod).
      def power_mod(base, exp, mod)
        base.pow(exp, mod)
      end

      # Deterministic round constants derived from hashing the ASCII string
      # "poseidon" with SHA-256, then chaining. This is a reproducible PRNG
      # approach (not the reference Grain LFSR, but deterministic and testable).
      def generate_round_constants
        @round_constants ||= begin
          require "openssl"
          num = (FULL_ROUNDS + PARTIAL_ROUNDS) * WIDTH
          constants = []
          seed = "poseidon_bn128_t#{WIDTH}"
          num.times do |i|
            hash_input = "#{seed}_rc_#{i}"
            hex = OpenSSL::Digest::SHA256.hexdigest(hash_input)
            constants << (hex.to_i(16) % FIELD_PRIME)
          end
          constants
        end
      end

      # Simple deterministic MDS matrix (Cauchy matrix construction).
      # M[i][j] = 1 / (x_i + y_j) mod p, where x and y are distinct sets.
      def generate_mds_matrix
        @mds_matrix ||= begin
          xs = (0...WIDTH).map { |i| i + 1 }
          ys = (0...WIDTH).map { |i| WIDTH + i + 1 }

          matrix = Array.new(WIDTH) { Array.new(WIDTH, 0) }
          WIDTH.times do |i|
            WIDTH.times do |j|
              val = (xs[i] + ys[j]) % FIELD_PRIME
              # Modular inverse via Fermat's little theorem: a^(p-2) mod p
              matrix[i][j] = val.pow(FIELD_PRIME - 2, FIELD_PRIME)
            end
          end
          matrix
        end
      end
    end
  end
end
