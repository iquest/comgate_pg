# frozen_string_literal: true

require "dry-struct"
require_relative "../types"

module ComgateApi
  module Requests
    class TransferList < Dry::Struct
      transform_keys(&:to_sym)

      # Required: date in YYYY-MM-DD format
      attribute :date, Types::Coercible::String

      # Optional: test mode
      attribute? :test, Types::Bool.optional

      def self.from_snake_case(**attrs)
        new(**attrs)
      end

      def validate!
        if date.nil? || date.to_s.strip.empty?
          raise ArgumentError, "date is required"
        end

        # Validate date format
        unless date.match?(/^\d{4}-\d{2}-\d{2}$/)
          raise ArgumentError, "date must be in YYYY-MM-DD format"
        end

        # Validate date is parseable
        begin
          Date.parse(date)
        rescue ArgumentError
          raise ArgumentError, "date must be a valid date (e.g., '2026-02-10')"
        end

        self
      end

      def to_params
        { date: date, test: test }.compact
      end
    end
  end
end
