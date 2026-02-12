# frozen_string_literal: true

module ComgateApi
  class ResponseValidator
    REQUIRED_CREATE_KEYS = %i[code message transId redirect].freeze

    def self.validate_create_payment!(data)
      missing = REQUIRED_CREATE_KEYS.reject { |key| data.key?(key) }
      unless missing.empty?
        raise ResponseValidationError, "Missing response keys: #{missing.join(", ") }"
      end

      return if data[:code].to_i.zero?

      raise ResponseValidationError, "API error: #{data[:code]} #{data[:message]}"
    end
  end
end
