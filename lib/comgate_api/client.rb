# frozen_string_literal: true

require "base64"
require "faraday"
require "json"
require_relative "requests/create_payment"
require_relative "requests/payment_status"
require_relative "requests/cancel_payment"
require_relative "requests/transfer_list"
require_relative "requests/single_transfer"

module ComgateApi
  # Main entry point for Comgate API requests.
  class Client
    # @param merchant_id [String, nil] Merchant identifier from Comgate portal
    # @param secret [String, nil] API secret from Comgate portal
    # @param base_url [String, nil] Base URL for API endpoints
    # @param timeout [Integer, nil] Request timeout in seconds
    # @param open_timeout [Integer, nil] Connection open timeout in seconds
    # @raise [ComgateApi::ConfigurationError] When credentials are missing
    def initialize(merchant_id: nil, secret: nil, base_url: nil, timeout: nil, open_timeout: nil)
      @config = ComgateApi.configuration
      @merchant_id = merchant_id || @config.merchant_id
      @secret = secret || @config.secret
      @base_url = base_url || @config.base_url
      @timeout = timeout || @config.timeout
      @open_timeout = open_timeout || @config.open_timeout

      validate_configuration!
    end

    # Create a payment and return the parsed response.
    # @param attrs [Hash] Request attributes for payment creation
    # @return [Hash] Parsed API response containing `transId` and `redirect`
    # @raise [ComgateApi::HTTPError] On non-2xx responses
    # @raise [ComgateApi::ResponseValidationError] On invalid responses
    def create_payment(**attrs)
      # Build and validate request using dry-struct
      request = Requests::CreatePayment.from_snake_case(**attrs)
      request.validate!

      payload = request.to_payload

      if payload[:method].to_s.strip.empty?
        default_method = @config.respond_to?(:methods) ? @config.methods : nil
        payload[:method] = default_method if default_method && !default_method.to_s.strip.empty?
      end

      if !payload.key?(:test) && @config.respond_to?(:test_mode) && @config.test_mode
        payload[:test] = true
      end

      response = connection.post("/v2.0/payment.json") do |req|
        req.headers.merge!(default_headers)
        req.body = JSON.generate(payload)
      end

      parsed = parse_json_response(response)
      ResponseValidator.validate_create_payment!(parsed)
      parsed
    end

    # Fetch transfer list for the given date.
    # @param attrs [Hash] Request attributes, including `date` and optional `test`
    # @return [Array<Hash>] Array of transfer summaries
    # @raise [ComgateApi::HTTPError] On non-2xx responses
    # @raise [ComgateApi::ResponseValidationError] On invalid JSON
    def transfer_list(**attrs)
      # Build and validate request
      request = Requests::TransferList.from_snake_case(**attrs)
      request.validate!

      params = request.to_params
      date = params[:date]

      # Apply global test mode if not explicitly provided
      use_test = params[:test].nil? ? (@config.respond_to?(:test_mode) && @config.test_mode) : params[:test]
      response = connection.get("/v2.0/transferList/date/#{date}.json") do |req|
        req.headers.merge!(default_headers)
        req.params[:test] = "true" if use_test
      end

      parse_json_response(response)
    end

    # Fetch detailed data for a single transfer.
    # @param attrs [Hash] Request attributes, including `transfer_id` (can be obtained from `transfer_list`) and optional `test`
    # @return [Array<Hash>] Array with transfer detail rows
    # @raise [ComgateApi::HTTPError] On non-2xx responses
    # @raise [ComgateApi::ResponseValidationError] On invalid JSON
    def single_transfer(**attrs)
      # Build and validate request
      request = Requests::SingleTransfer.from_snake_case(**attrs)
      request.validate!

      params = request.to_params
      transfer_id = params[:transfer_id]

      # Apply global test mode if not explicitly provided
      use_test = params[:test].nil? ? (@config.respond_to?(:test_mode) && @config.test_mode) : params[:test]
      response = connection.get("/v2.0/singleTransfer/transferId/#{transfer_id}.json") do |req|
        req.headers.merge!(default_headers)
        req.params[:test] = "true" if use_test
      end

      parse_json_response(response)
    end

    # Cancel a pending payment by transaction ID.
    # @param attrs [Hash] Request attributes, including `trans_id`
    # @return [Hash] Parsed API response
    # @raise [ComgateApi::HTTPError] On non-2xx responses
    # @raise [ComgateApi::ResponseValidationError] On invalid JSON
    def cancel_payment(**attrs)
      # Build and validate request
      request = Requests::CancelPayment.from_snake_case(**attrs)
      request.validate!

      trans_id = request.to_params[:trans_id]

      response = connection.delete("/v2.0/payment/transId/#{trans_id}.json") do |req|
        req.headers.merge!(default_headers)
      end

      parse_json_response(response)
    end

    # Fetch payment status by transaction ID.
    # @param attrs [Hash] Request attributes, including `trans_id`
    # @return [Hash] Parsed API response
    # @raise [ComgateApi::HTTPError] On non-2xx responses
    # @raise [ComgateApi::ResponseValidationError] On invalid JSON
    def payment_status(**attrs)
      # Build and validate request
      request = Requests::PaymentStatus.from_snake_case(**attrs)
      request.validate!

      trans_id = request.to_params[:trans_id]

      response = connection.get("/v2.0/payment/transId/#{trans_id}.json") do |req|
        req.headers.merge!(default_headers)
      end

      parse_json_response(response)
    end

    private

    def validate_configuration!
      missing = []
      missing << "merchant_id" if @merchant_id.to_s.strip.empty?
      missing << "secret" if @secret.to_s.strip.empty?
      return if missing.empty?

      raise ConfigurationError, "Missing configuration: #{missing.join(", ")}"
    end

    def connection
      @connection ||= Faraday.new(url: @base_url) do |conn|
        conn.options.timeout = @timeout
        conn.options.open_timeout = @open_timeout
      end
    end

    def default_headers
      token = Base64.strict_encode64("#{@merchant_id}:#{@secret}")
      {
        "Authorization" => "Basic #{token}",
        "Content-Type" => "application/json",
        "Accept" => "application/json"
      }
    end

    def parse_json_response(response)
      unless response.status.between?(200, 299)
        raise HTTPError.new(status: response.status, body: response.body)
      end

      JSON.parse(response.body, symbolize_names: true)
    rescue JSON::ParserError => e
      raise ResponseValidationError, "Invalid JSON response: #{e.message}"
    end

  end
end
