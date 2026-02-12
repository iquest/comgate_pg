#!/usr/bin/env ruby
# frozen_string_literal: true

require "dotenv/load"
require "comgate_api"
require "json"

trans_id = ARGV[0]

unless trans_id
  puts "❌ Error: Transaction ID is required"
  puts "\nUsage:"
  puts "  ruby script/test_cancel_payment.rb AB12-CD34-EF56"
  puts "  COMGATE_TRANS_ID=AB12-CD34-EF56 ruby script/test_cancel_payment.rb"
  puts "  rake comgate:test_cancel_payment TRANS_ID=AB12-CD34-EF56"
  exit 1
end

client = ComgateApi::Client.new
puts "\n🔍 Testing cancel_payment endpoint..."
puts "🎫 Transaction ID: #{trans_id}"
puts "⚠️  WARNING: This will cancel the payment if it's in PENDING state!"
puts "-" * 60

begin
  response = client.cancel_payment(trans_id: trans_id)

  puts "✅ Payment cancelled successfully!\n\n"
  puts "Code: #{response[:code]}"
  puts "Message: #{response[:message]}"

  puts "\n📊 Full Response:"
  puts JSON.pretty_generate(response)
rescue ComgateApi::HTTPError => e
  puts "❌ HTTP Error #{e.status}:"
  puts e.body
  begin
    parsed = JSON.parse(e.body, symbolize_names: true)
    puts "\nParsed error:"
    puts "  Code: #{parsed[:code]}"
    puts "  Message: #{parsed[:message]}"

    if parsed[:code] == 1400
      puts "\n💡 Tip: Payment can only be cancelled when status is PENDING"
      puts "   Use payment_status to check current state"
    end
  rescue JSON::ParserError
    # Not JSON, already printed raw body
  end
  exit 1
rescue ComgateApi::ConfigurationError => e
  puts "❌ Configuration Error: #{e.message}"
  puts "   Please check your .env file with COMGATE_MERCHANT_ID and COMGATE_SECRET"
  exit 1
rescue ArgumentError => e
  puts "❌ Validation Error: #{e.message}"
  exit 1
rescue StandardError => e
  puts "❌ Error: #{e.class} - #{e.message}"
  puts e.backtrace.first(5)
  exit 1
end
