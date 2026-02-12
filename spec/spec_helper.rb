# frozen_string_literal: true

require "comgate_api"
require "webmock/rspec"

RSpec.configure do |config|
	config.disable_monkey_patching!
	config.expect_with :rspec do |c|
		c.syntax = :expect
	end
end
