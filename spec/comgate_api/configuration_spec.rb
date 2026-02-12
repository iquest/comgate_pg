# frozen_string_literal: true

require "spec_helper"

RSpec.describe ComgateApi::Configuration do
  around do |example|
    original_env = ENV.to_h
    begin
      ENV["COMGATE_MERCHANT_ID"] = "merchant-123"
      ENV["COMGATE_SECRET"] = "secret-abc"
      ENV["COMGATE_BASE_URL"] = "https://example.com"
      example.run
    ensure
      ENV.replace(original_env)
    end
  end

  it "loads defaults from environment" do
    config = described_class.new

    expect(config.merchant_id).to eq("merchant-123")
    expect(config.secret).to eq("secret-abc")
    expect(config.base_url).to eq("https://example.com")
    expect(config.timeout).to eq(60)
    expect(config.open_timeout).to eq(20)
  end
end