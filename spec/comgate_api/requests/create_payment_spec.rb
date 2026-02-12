# frozen_string_literal: true

require "spec_helper"
require "comgate_api/requests/create_payment"

RSpec.describe ComgateApi::Requests::CreatePayment do
  describe ".from_snake_case" do
    it "converts snake_case keys to camelCase" do
      request = described_class.from_snake_case(
        price: 10000,
        curr: "CZK",
        label: "Test Order",
        ref_id: "order-123",
        full_name: "Jan Novák",
        billing_addr_city: "Praha"
      )

      expect(request.refId).to eq("order-123")
      expect(request.fullName).to eq("Jan Novák")
      expect(request.billingAddrCity).to eq("Praha")
    end
  end

  describe "#validate!" do
    let(:valid_attrs) do
      {
        price: 10000,
        curr: "CZK",
        label: "Test",
        refId: "order-123",
        email: "test@example.com"
      }
    end

    it "passes validation with valid attributes" do
      request = described_class.new(**valid_attrs)
      expect { request.validate! }.not_to raise_error
    end

    context "contact information" do
      it "requires either email or phone" do
        request = described_class.new(**valid_attrs.merge(email: nil))
        expect { request.validate! }.to raise_error(ArgumentError, /email or phone/)
      end

      it "accepts phone instead of email" do
        request = described_class.new(**valid_attrs.merge(email: nil, phone: "+420777123456"))
        expect { request.validate! }.not_to raise_error
      end
    end

    context "price validation" do
      it "enforces minimum price constraint (100 haléř)" do
        expect {
          described_class.new(**valid_attrs.merge(price: 50))
        }.to raise_error(Dry::Struct::Error, /violates constraints/)
      end

      it "accepts valid prices above minimum" do
        request = described_class.new(**valid_attrs.merge(price: 1000, curr: "EUR"))
        expect { request.validate! }.not_to raise_error
      end

      it "lets API validate currency-specific price ranges" do
        # Price range validation per currency is handled by API
        request = described_class.new(**valid_attrs.merge(price: 200_000_000, curr: "CZK"))
        expect { request.validate! }.not_to raise_error
      end
    end

    context "currency handling" do
      it "accepts any currency string (API validates)" do
        request = described_class.new(**valid_attrs.merge(curr: "HUF"))
        expect { request.validate! }.not_to raise_error
      end

      it "lets API validate HUF decimal rules" do
        # HUF decimal validation is handled by API
        request = described_class.new(**valid_attrs.merge(price: 10050, curr: "HUF"))
        expect { request.validate! }.not_to raise_error
      end
    end

    context "label validation" do
      it "enforces 1-16 character limit" do
        expect {
          described_class.new(**valid_attrs.merge(label: ""))
        }.to raise_error(Dry::Struct::Error)

        expect {
          described_class.new(**valid_attrs.merge(label: "a" * 17))
        }.to raise_error(Dry::Struct::Error)
      end

      it "accepts valid label" do
        request = described_class.new(**valid_attrs.merge(label: "Valid Label"))
        expect { request.validate! }.not_to raise_error
      end
    end

    context "currency validation" do
      it "accepts any currency string and lets API validate" do
        # API will return error for invalid currencies
        request = described_class.new(**valid_attrs.merge(curr: "XXX"))
        expect(request.curr).to eq("XXX")
      end

      it "accepts valid currencies" do
        %w[CZK EUR PLN HUF USD GBP RON NOK SEK].each do |curr|
          request = described_class.new(**valid_attrs.merge(curr: curr))
          expect(request.curr).to eq(curr)
        end
      end
    end

    context "delivery validation" do
      it "requires home delivery address when delivery=HOME_DELIVERY" do
        request = described_class.new(**valid_attrs.merge(delivery: "HOME_DELIVERY"))
        expect { request.validate! }.to raise_error(ArgumentError, /HOME_DELIVERY requires/)
      end

      it "accepts home delivery with complete address" do
        request = described_class.new(**valid_attrs.merge(
          delivery: "HOME_DELIVERY",
          homeDeliveryCity: "Praha",
          homeDeliveryStreet: "Main St 123",
          homeDeliveryPostalCode: "12000",
          homeDeliveryCountry: "CZ"
        ))
        expect { request.validate! }.not_to raise_error
      end

      it "accepts PICKUP without address" do
        request = described_class.new(**valid_attrs.merge(delivery: "PICKUP"))
        expect { request.validate! }.not_to raise_error
      end
    end

    context "expiration time validation" do
      it "validates expiration time format" do
        request = described_class.new(**valid_attrs.merge(expirationTime: "invalid"))
        expect { request.validate! }.to raise_error(ArgumentError, /expirationTime must be in format/)
      end

      it "accepts valid expiration time formats" do
        %w[30m 10h 2d].each do |time|
          request = described_class.new(**valid_attrs.merge(expirationTime: time))
          expect { request.validate! }.not_to raise_error
        end
      end
    end

    context "optional boolean fields" do
      it "accepts boolean values" do
        request = described_class.new(**valid_attrs.merge(
          test: true,
          preauth: false,
          initRecurring: true,
          verification: false
        ))
        expect { request.validate! }.not_to raise_error
        expect(request.test).to eq(true)
        expect(request.preauth).to eq(false)
      end
    end
  end

  describe "#to_payload" do
    it "returns hash with compact values" do
      request = described_class.new(
        price: 10000,
        curr: "CZK",
        label: "Test",
        refId: "order-123",
        email: "test@example.com",
        fullName: "Jan Novák"
      )

      payload = request.to_payload

      expect(payload[:price]).to eq(10000)
      expect(payload[:curr]).to eq("CZK")
      expect(payload[:email]).to eq("test@example.com")
      expect(payload[:fullName]).to eq("Jan Novák")
      expect(payload).not_to have_key(:phone)  # nil values removed
    end
  end
end

