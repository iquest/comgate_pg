# frozen_string_literal: true

module ComgateApi
  class Error < StandardError; end
  class ConfigurationError < Error; end
  class HTTPError < Error
    attr_reader :status, :body

    def initialize(status:, body: nil, message: nil)
      @status = status
      @body = body
      super(message || "HTTP error: #{status}")
    end
  end
  class ResponseValidationError < Error; end
end
