# frozen_string_literal: true

module ComgateApi
  BASE_URL = "https://payments.comgate.cz".freeze

  # Configuration container for ComgateApi.
  #
  # @!attribute [rw] merchant_id
  #   @return [String, nil] Merchant identifier from Comgate portal
  # @!attribute [rw] secret
  #   @return [String, nil] API secret from Comgate portal
  # @!attribute [rw] base_url
  #   @return [String] Base URL for API endpoints
  # @!attribute [rw] timeout
  #   @return [Integer] Request timeout in seconds
  # @!attribute [rw] open_timeout
  #   @return [Integer] Connection open timeout in seconds
  # @!attribute [rw] test_mode
  #   @return [Boolean] Default test mode for requests
  # @!attribute [rw] methods
  #   @return [String] Default payment method filter
  class Configuration
    attr_accessor :merchant_id, :secret, :base_url, :timeout, :open_timeout, :test_mode, :methods

    def initialize
      @merchant_id = ENV["COMGATE_MERCHANT_ID"]
      @secret = ENV["COMGATE_SECRET"]
      @base_url = ENV.fetch("COMGATE_BASE_URL", BASE_URL)
      @timeout = 60
      @open_timeout = 20
      @test_mode = ENV.fetch("COMGATE_TEST", "false").downcase == "true"
      @methods = ENV.fetch("COMGATE_METHODS", "ALL")
    end
  end
end
