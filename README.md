# ComgateApi

Ruby wrapper for the Comgate payment gateway API v2.0.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "comgate_api"
```

And then execute:

```bash
bundle install
```

## Overview

The Comgate REST API (Merchant API) v2.0 lets your backend create and manage payments via Comgate. All communication must be server-to-server — never expose your API secret in client-side code.

**Base URL:** `https://payments.comgate.cz`

**Authentication:** HTTP Basic Auth with `Authorization: Basic <base64(merchant:secret)>`

## Configuration

### Environment Variables

Create a `.env` file in your project root:

```bash
COMGATE_MERCHANT_ID=your_merchant_id
COMGATE_SECRET=your_secret_key
COMGATE_BASE_URL=https://payments.comgate.cz
COMGATE_TEST=true  # optional: automatically add test=true to requests
COMGATE_METHODS=ALL  # optional: default payment method selection
```

Load variables using `dotenv`:

```ruby
require "dotenv/load"
require "comgate_api"
```

### Global Configuration Block

For Rails apps, create `config/initializers/comgate_api.rb`:

```ruby
ComgateApi.configure do |config|
  config.merchant_id = ENV["COMGATE_MERCHANT_ID"]
  config.secret = ENV["COMGATE_SECRET"]
  config.base_url = ENV.fetch("COMGATE_BASE_URL", "https://payments.comgate.cz")
  config.timeout = 30
  config.open_timeout = 10
  config.test_mode = ENV["COMGATE_TEST"] == "true"
  config.methods = ENV["COMGATE_METHODS"] || "ALL"
end
```

### Per-Instance Configuration

```ruby
client = ComgateApi::Client.new(
  merchant_id: "your_merchant_id",
  secret: "your_secret",
  base_url: "https://payments.comgate.cz",
  timeout: 30,
  open_timeout: 10
)
```

## Usage

### Create Payment

```ruby
require "comgate_api"

client = ComgateApi::Client.new  # uses global config or env vars

# Create a payment (price in cents/haléř, minimum 100 = 1 CZK)
response = client.create_payment(
  price: 10000,        # 100.00 CZK
  curr: "CZK",
  label: "Order #123",
  ref_id: "order-123",
  method: "ALL",       # or specific method like "CARD_CZ_CSOB_2"
  email: "customer@example.com",
  phone: "+420777123456",
  fullName: "Jan Novák"
)

# Response includes:
# {
#   code: 0,
#   message: "OK",
#   transId: "AB12-CD34-EF56",
#   redirect: "https://payments.comgate.cz/client/instructions/index?id=AB12-CD34-EF56"
# }

# Redirect customer to the payment page
redirect_to response[:redirect]

# Store transId for status checks
order.update!(comgate_trans_id: response[:transId])
```

### Check Payment Status

```ruby
status = client.payment_status(trans_id: "AB12-CD34-EF56")

# Response includes:
# {
#   code: 0,
#   message: "OK",
#   transId: "AB12-CD34-EF56",
#   status: "PAID",  # or "PENDING", "CANCELLED", "AUTHORIZED"
#   refId: "order-123",
#   price: "10000",
#   curr: "CZK",
#   # ... additional fields
# }

case status[:status]
when "PAID"
  # Mark order as paid
  order.mark_as_paid!
when "PENDING"
  # Still waiting for payment
when "CANCELLED"
  # Payment was cancelled
end
```

### Cancel Pending Payment

```ruby
# Cancel a payment that's still in PENDING state
response = client.cancel_payment(trans_id: "AB12-CD34-EF56")

# Response:
# {
#   code: 0,
#   message: "OK"
# }
```

**Note:** You can only cancel payments in `PENDING` state. For completed payments, use refund (not yet implemented).

### List Transfers

```ruby
# Get list of transfers for a specific date
transfers = client.transfer_list(date: "2026-02-10")

# Response is an array:
# [
#   {
#     transferId: 1234567,
#     transferDate: "2026-02-10",
#     accountCounterparty: "123456789/0800",
#     accountOutgoing: "987654321/0100",
#     variableSymbol: "12345678",
#     price: "10000",
#     curr: "CZK"
#   },
#   # ...
# ]

transfers.each do |transfer|
  puts "Transfer #{transfer[:transferId]}: #{transfer[:price]} #{transfer[:curr]}"
end
```

## Error Handling

```ruby
begin
  response = client.create_payment(
    price: 50,  # Too small! Minimum is 100 (1 CZK)
    curr: "CZK",
    label: "Test",
    ref_id: "test-001"
  )
rescue ComgateApi::HTTPError => e
  puts "HTTP Error: #{e.status}"
  puts "Response body: #{e.body}"
  # Example: {"code":1309,"message":"Invalid payment amount"}

  body = JSON.parse(e.body, symbolize_names: true)
  case body[:code]
  when 1309
    # Handle invalid amount
  when 1301
    # Handle unknown merchant
  end
rescue ComgateApi::ConfigurationError => e
  puts "Configuration error: #{e.message}"
rescue ComgateApi::ResponseValidationError => e
  puts "Invalid response: #{e.message}"
end
```

## Testing & Development

### Console

Start an interactive console with your configuration loaded:

```bash
bundle exec ./bin/console
```

### Test Scripts

Each endpoint has a dedicated test script you can run directly:

```bash
# Create a test payment
./script/test_create_payment.rb

# Check payment status (requires transaction ID)
./script/test_payment_status.rb AB12-CD34-EF56

# Cancel a pending payment (requires transaction ID)
./script/test_cancel_payment.rb AB12-CD34-EF56

# List transfers for a date
COMGATE_TEST_DATE=2026-02-10 ./script/test_transfer_list.rb
```

### Rake Tasks

All test scripts are also available as rake tasks:

```bash
# List all available tasks
bundle exec rake comgate:list

# Test payment creation
bundle exec rake comgate:test_create_payment

# Test payment status
bundle exec rake comgate:test_payment_status TRANS_ID=AB12-CD34-EF56

# Test payment cancellation
bundle exec rake comgate:test_cancel_payment TRANS_ID=AB12-CD34-EF56

# Test transfer list
bundle exec rake comgate:test_transfer_list
bundle exec rake comgate:test_transfer_list COMGATE_TEST_DATE=2026-02-10
```

### RSpec Tests

Run the test suite:

```bash
bundle exec rspec
```

Run specific tests:

```bash
bundle exec rspec spec/comgate_api/create_payment_spec.rb
bundle exec rspec spec/comgate_api/cancel_payment_spec.rb
```

### Debugging with rdbg

```bash
bundle exec rdbg ./bin/console

# Inside debugger:
(rdbg) break ComgateApi::Client#create_payment
(rdbg) continue
```

## Sandbox & Testing

- Set `COMGATE_TEST=true` to automatically add `test=true` to all requests
- Use Comgate sandbox credentials for integration testing
- Test payments with `test=true` won't charge real money
- Minimum payment amount: 100 haléř = 1 CZK

## API Reference

### Implemented Methods

| Method | Endpoint | Description |
|--------|----------|-------------|
| `create_payment` | `POST /v2.0/payment.json` | Create a new payment |
| `payment_status` | `GET /v2.0/payment/transId/{transId}.json` | Get payment status |
| `cancel_payment` | `DELETE /v2.0/payment/transId/{transId}.json` | Cancel pending payment |
| `transfer_list` | `GET /v2.0/transferList/date/{date}.json` | List transfers for date |

### Payment Methods

Common payment method codes:
- `ALL` - Show all available methods to customer
- `CARD_CZ_CSOB_2` - Card payment (Czech)
- `BANK_CZ_CS_P` - Česká spořitelna
- `BANK_CZ_KB` - Komerční banka
- See full list: https://help.comgate.cz/docs/en/payment-methods

### Error Codes

Common API error codes:
- `0` - OK
- `1309` - Invalid payment amount
- `1301` - Unknown merchant
- `1400` - Bad request / Cannot cancel payment (wrong state)

## Resources

- [Comgate API Documentation](https://apidoc.comgate.cz/en/)
- [Payment Methods](https://help.comgate.cz/docs/en/payment-methods)
- [API Protocol](https://help.comgate.cz/docs/en/api-protocol-en)

## License

MIT
