# frozen_string_literal: true

require "dry-struct"
require_relative "../types"

module ComgateApi
  module Requests
    class SingleTransfer < Dry::Struct
      transform_keys(&:to_sym)

      # Required: transfer ID
      attribute :transfer_id, Types::Coercible::String

      # Optional: test mode
      attribute? :test, Types::Bool.optional

      def self.from_snake_case(**attrs)
        new(transfer_id: attrs[:transfer_id], test: attrs[:test])
      end

      def validate!
        if transfer_id.nil? || transfer_id.to_s.strip.empty?
          raise ArgumentError, "transfer_id is required"
        end
        self
      end

      def to_params
        { transfer_id: transfer_id, test: test }.compact
      end
    end
  end
end
