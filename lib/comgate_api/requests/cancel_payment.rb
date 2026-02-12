# frozen_string_literal: true

require "dry-struct"
require_relative "../types"

module ComgateApi
  module Requests
    class CancelPayment < Dry::Struct
      transform_keys(&:to_sym)

      # Required: transaction ID
      attribute :trans_id, Types::Coercible::String

      def self.from_snake_case(**attrs)
        new(trans_id: attrs[:trans_id])
      end

      def validate!
        if trans_id.nil? || trans_id.to_s.strip.empty?
          raise ArgumentError, "trans_id is required"
        end
        self
      end

      def to_params
        { trans_id: trans_id }
      end
    end
  end
end
