# frozen_string_literal: true

require "spec_helper"
require "comgate_api/requests/transfer_list"

RSpec.describe ComgateApi::Requests::TransferList do
  describe "#validate!" do
    it "requires date parameter" do
      request = described_class.new(date: nil)
      expect { request.validate! }.to raise_error(ArgumentError, /date is required/)
    end

    it "requires date in YYYY-MM-DD format" do
      request = described_class.new(date: "2026/02/10")
      expect { request.validate! }.to raise_error(ArgumentError, /YYYY-MM-DD format/)
    end

    it "validates date is parseable" do
      request = described_class.new(date: "2026-13-40")
      expect { request.validate! }.to raise_error(ArgumentError, /valid date/)
    end

    it "accepts valid date" do
      request = described_class.new(date: "2026-02-10")
      expect { request.validate! }.not_to raise_error
    end

    it "accepts optional test parameter" do
      request = described_class.new(date: "2026-02-10", test: true)
      expect { request.validate! }.not_to raise_error
    end
  end

  describe "#to_params" do
    it "returns params hash" do
      request = described_class.new(date: "2026-02-10", test: true)
      params = request.to_params

      expect(params[:date]).to eq("2026-02-10")
      expect(params[:test]).to eq(true)
    end

    it "omits nil values" do
      request = described_class.new(date: "2026-02-10")
      params = request.to_params

      expect(params[:date]).to eq("2026-02-10")
      expect(params).not_to have_key(:test)
    end
  end
end
