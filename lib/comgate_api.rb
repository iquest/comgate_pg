# frozen_string_literal: true

require_relative "comgate_api/version"
require_relative "comgate_api/configuration"
require_relative "comgate_api/errors"
require_relative "comgate_api/response_validator"
require_relative "comgate_api/client"

module ComgateApi
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end
  end
end
