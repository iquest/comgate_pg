# frozen_string_literal: true

require "spec_helper"

RSpec.describe ComgateApi::Client do
  describe "configuration" do
    it "raises when required configuration is missing" do
      expect { described_class.new(merchant_id: nil, secret: nil) }
        .to raise_error(ComgateApi::ConfigurationError, /merchant_id, secret/)
    end

    it "accepts explicit credentials" do
      client = described_class.new(merchant_id: "merchant-1", secret: "secret-1")
      expect(client).to be_a(described_class)
    end

    it "uses global configuration by default" do
      ComgateApi.configure do |config|
        config.merchant_id = "merchant-2"
        config.secret = "secret-2"
      end

      client = described_class.new
      expect(client).to be_a(described_class)
    ensure
      ComgateApi.configure do |config|
        config.merchant_id = nil
        config.secret = nil
      end
    end
  end

  describe "#create_payment" do
    let(:client) { described_class.new(merchant_id: "merchant-1", secret: "secret-1") }

    it "creates a payment and returns parsed response" do
      stub_request(:post, "https://payments.comgate.cz/v2.0/payment.json")
        .with(
          headers: {
            "Authorization" => /Basic /,
            "Content-Type" => "application/json",
            "Accept" => "application/json"
          },
          body: hash_including(
            "price" => 1000,
            "curr" => "CZK",
            "label" => "Product",
            "refId" => "order-1",
            "email" => "payer@example.com"
          )
        )
        .to_return(
          status: 201,
          body: {
            code: 0,
            message: "OK",
            transId: "AB12-CD34-EF56",
            redirect: "https://payments.comgate.cz/client/instructions/index?id=AB12-CD34-EF56"
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      response = client.create_payment(
        price: 1000,
        curr: "CZK",
        label: "Product",
        ref_id: "order-1",
        method: "ALL",
        email: "payer@example.com"
      )

      expect(response[:code]).to eq(0)
      expect(response[:redirect]).to include("https://payments.comgate.cz")
    end

    it "raises on API error code" do
      stub_request(:post, "https://payments.comgate.cz/v2.0/payment.json")
        .to_return(
          status: 201,
          body: { code: 1100, message: "unknown error", transId: "", redirect: "" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      expect do
        client.create_payment(
          price: 1000,
          curr: "CZK",
          label: "Product",
          ref_id: "order-1",
          method: "ALL",
          email: "payer@example.com"
        )
      end.to raise_error(ComgateApi::ResponseValidationError, /API error/)
    end
  end

  describe "#payment_status" do
    let(:merchant_id) { "merchant123" }
    let(:secret) { "secret_key" }
    let(:base_url) { "https://payments.comgate.cz" }
    let(:client) { described_class.new(merchant_id: merchant_id, secret: secret, base_url: base_url) }

    let(:sample_status) do
      {
        code: 0,
        message: "OK",
        test: "true",
        price: "100",
        curr: "CZK",
        label: "paytest",
        refId: "order-1",
        email: "test@example.com",
        transId: "AB12-CD34-EF56",
        status: "PENDING"
      }
    end

    before do
      stub_request(:get, "#{base_url}/v2.0/payment/transId/AB12-CD34-EF56.json")
        .with(
          headers: {
            "Authorization" => /Basic /,
            "Content-Type" => "application/json",
            "Accept" => "application/json"
          }
        )
        .to_return(
          status: 200,
          body: JSON.generate(sample_status),
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "requests payment status and parses response" do
      result = client.payment_status(trans_id: "AB12-CD34-EF56")
      expect(result).to be_a(Hash)
      expect(result[:code]).to eq(0)
      expect(result[:transId]).to eq("AB12-CD34-EF56")
      expect(result[:status]).to eq("PENDING")
    end

    context "when API returns non-200" do
      before do
        stub_request(:get, "#{base_url}/v2.0/payment/transId/NOTFOUND.json")
          .with(headers: { "Authorization" => /Basic / })
          .to_return(status: 404, body: "Not found")
      end

      it "raises HTTPError" do
        expect { client.payment_status(trans_id: "NOTFOUND") }.to raise_error(ComgateApi::HTTPError)
      end
    end
  end

  describe "#cancel_payment" do
    let(:merchant_id) { "merchant123" }
    let(:secret) { "secret_key" }
    let(:base_url) { "https://payments.comgate.cz" }
    let(:client) { described_class.new(merchant_id: merchant_id, secret: secret, base_url: base_url) }

    let(:success_response) do
      {
        code: 0,
        message: "OK"
      }
    end

    before do
      stub_request(:delete, "#{base_url}/v2.0/payment/transId/AB12-CD34-EF56.json")
        .with(
          headers: {
            "Authorization" => /Basic /,
            "Content-Type" => "application/json",
            "Accept" => "application/json"
          }
        )
        .to_return(
          status: 200,
          body: JSON.generate(success_response),
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "sends DELETE to cancel endpoint and returns parsed response" do
      result = client.cancel_payment(trans_id: "AB12-CD34-EF56")
      expect(result).to be_a(Hash)
      expect(result[:code]).to eq(0)
      expect(result[:message]).to eq("OK")
    end

    context "when API returns non-2xx" do
      before do
        stub_request(:delete, "#{base_url}/v2.0/payment/transId/NOTFOUND.json")
          .with(headers: { "Authorization" => /Basic / })
          .to_return(status: 404, body: "Not found")
      end

      it "raises HTTPError" do
        expect { client.cancel_payment(trans_id: "NOTFOUND") }.to raise_error(ComgateApi::HTTPError)
      end
    end
  end

  describe "#transfer_list" do
    let(:merchant_id) { "merchant123" }
    let(:secret) { "secret_key" }
    let(:base_url) { "https://payments.comgate.cz" }
    let(:client) { described_class.new(merchant_id: merchant_id, secret: secret, base_url: base_url) }

    let(:sample_transfer_list) do
      [
        {
          transferId: 1234567,
          transferDate: "2025-02-10",
          accountCounterparty: "0/0000",
          accountOutgoing: "123456789/0000",
          variableSymbol: "12345678"
        }
      ]
    end

    before do
      stub_request(:get, "#{base_url}/v2.0/transferList/date/2025-02-10.json")
        .with(
          headers: {
            "Authorization" => /Basic /,
            "Content-Type" => "application/json",
            "Accept" => "application/json"
          }
        )
        .to_return(
          status: 200,
          body: JSON.generate(sample_transfer_list),
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "makes a GET request to the transfer list endpoint" do
      client.transfer_list(date: "2025-02-10")
      expect(
        a_request(:get, "#{base_url}/v2.0/transferList/date/2025-02-10.json")
          .with(headers: { "Authorization" => /Basic / })
      ).to have_been_made
    end

    it "returns an array of transfers" do
      result = client.transfer_list(date: "2025-02-10")
      expect(result).to be_an(Array)
      expect(result.length).to eq(1)
    end

    it "parses the response correctly" do
      result = client.transfer_list(date: "2025-02-10")
      transfer = result.first
      expect(transfer[:transferId]).to eq(1234567)
      expect(transfer[:transferDate]).to eq("2025-02-10")
      expect(transfer[:accountCounterparty]).to eq("0/0000")
      expect(transfer[:accountOutgoing]).to eq("123456789/0000")
      expect(transfer[:variableSymbol]).to eq("12345678")
    end

    context "when API returns empty array" do
      before do
        stub_request(:get, "#{base_url}/v2.0/transferList/date/2025-02-01.json")
          .with(headers: { "Authorization" => /Basic / })
          .to_return(
            status: 200,
            body: JSON.generate([]),
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "returns an empty array" do
        result = client.transfer_list(date: "2025-02-01")
        expect(result).to eq([])
      end
    end

    context "when API returns HTTP error" do
      before do
        stub_request(:get, "#{base_url}/v2.0/transferList/date/2025-02-01.json")
          .with(headers: { "Authorization" => /Basic / })
          .to_return(status: 403, body: "Forbidden")
      end

      it "raises HTTPError" do
        expect {
          client.transfer_list(date: "2025-02-01")
        }.to raise_error(ComgateApi::HTTPError)
      end
    end

    context "when API returns invalid JSON" do
      before do
        stub_request(:get, "#{base_url}/v2.0/transferList/date/2025-02-01.json")
          .with(headers: { "Authorization" => /Basic / })
          .to_return(
            status: 200,
            body: "not valid json {[",
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "raises ResponseValidationError" do
        expect {
          client.transfer_list(date: "2025-02-01")
        }.to raise_error(ComgateApi::ResponseValidationError)
      end
    end
  end

  describe "#single_transfer" do
    let(:merchant_id) { "merchant123" }
    let(:secret) { "secret_key" }
    let(:base_url) { "https://payments.comgate.cz" }
    let(:client) { described_class.new(merchant_id: merchant_id, secret: secret, base_url: base_url) }

    let(:sample_transfer) do
      [
        {
          typ: 1,
          Merchant: "123456",
          "Datum zalozeni": "2023-01-06 14:11:30",
          "Datum zaplaceni": "2023-01-06 14:21:30",
          "Datum prevodu": "2023-01-10",
          "ID Comgate": "AAAA-BBBB-CCCC",
          Metoda: "Card payment",
          Popis: "description eshop payment",
          "E-mail platce": "name.lastname@email.cz",
          "Variabilni symbol platce": "123456789",
          "ID od klienta": "1234",
          Mena: "EUR",
          "Potvrzena castka": "10,00"
        }
      ]
    end

    before do
      stub_request(:get, "#{base_url}/v2.0/singleTransfer/transferId/1234567.json")
        .with(
          headers: {
            "Authorization" => /Basic /,
            "Content-Type" => "application/json",
            "Accept" => "application/json"
          }
        )
        .to_return(
          status: 200,
          body: JSON.generate(sample_transfer),
          headers: { "Content-Type" => "application/json" }
        )
    end

    it "makes a GET request to the single transfer endpoint" do
      client.single_transfer(transfer_id: "1234567")
      expect(
        a_request(:get, "#{base_url}/v2.0/singleTransfer/transferId/1234567.json")
          .with(headers: { "Authorization" => /Basic / })
      ).to have_been_made
    end

    it "returns an array of transfer details" do
      result = client.single_transfer(transfer_id: "1234567")
      expect(result).to be_an(Array)
      expect(result.length).to eq(1)
    end

    it "parses the response correctly" do
      result = client.single_transfer(transfer_id: "1234567")
      transfer = result.first
      expect(transfer[:typ]).to eq(1)
      expect(transfer[:Merchant]).to eq("123456")
      expect(transfer[:"Datum prevodu"]).to eq("2023-01-10")
      expect(transfer[:"ID Comgate"]).to eq("AAAA-BBBB-CCCC")
    end

    context "when API returns empty array" do
      before do
        stub_request(:get, "#{base_url}/v2.0/singleTransfer/transferId/0000000.json")
          .with(headers: { "Authorization" => /Basic / })
          .to_return(
            status: 200,
            body: JSON.generate([]),
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "returns an empty array" do
        result = client.single_transfer(transfer_id: "0000000")
        expect(result).to eq([])
      end
    end

    context "when API returns HTTP error" do
      before do
        stub_request(:get, "#{base_url}/v2.0/singleTransfer/transferId/0000000.json")
          .with(headers: { "Authorization" => /Basic / })
          .to_return(status: 403, body: "Forbidden")
      end

      it "raises HTTPError" do
        expect {
          client.single_transfer(transfer_id: "0000000")
        }.to raise_error(ComgateApi::HTTPError)
      end
    end

    context "when API returns invalid JSON" do
      before do
        stub_request(:get, "#{base_url}/v2.0/singleTransfer/transferId/0000000.json")
          .with(headers: { "Authorization" => /Basic / })
          .to_return(
            status: 200,
            body: "not valid json {[",
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "raises ResponseValidationError" do
        expect {
          client.single_transfer(transfer_id: "0000000")
        }.to raise_error(ComgateApi::ResponseValidationError)
      end
    end
  end
end