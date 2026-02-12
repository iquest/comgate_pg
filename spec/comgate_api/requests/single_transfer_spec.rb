# frozen_string_literal: true

require "spec_helper"
require "comgate_api/requests/single_transfer"

RSpec.describe ComgateApi::Requests::SingleTransfer do
  describe "#validate!" do
    it "requires transfer_id" do
      request = described_class.new(transfer_id: nil)
      expect { request.validate! }.to raise_error(ArgumentError, /transfer_id is required/)
    end

    it "accepts valid transfer_id" do
      request = described_class.new(transfer_id: "1234567")
      expect { request.validate! }.not_to raise_error
    end

    it "accepts optional test parameter" do
      request = described_class.new(transfer_id: "1234567", test: true)
      expect { request.validate! }.not_to raise_error
    end
  end

  describe "#to_params" do
    it "returns params hash" do
      request = described_class.new(transfer_id: "1234567", test: true)
      params = request.to_params

      expect(params[:transfer_id]).to eq("1234567")
      expect(params[:test]).to eq(true)
    end

    it "omits nil values" do
      request = described_class.new(transfer_id: "1234567")
      params = request.to_params

      expect(params[:transfer_id]).to eq("1234567")
      expect(params).not_to have_key(:test)
    end
  end
end
