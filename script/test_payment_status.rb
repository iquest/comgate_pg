#!/usr/bin/env ruby
# frozen_string_literal: true

require "dotenv/load"
require "comgate_api"
require "json"

trans_id = ARGV[0] || "AB12-CD34-EF56" # Replace with actual transId for testing

unless trans_id
  puts "❌ Error: Transaction ID is required"
  puts "\nUsage:"
  puts "  ruby script/test_payment_status.rb ç"
  puts "  COMGATE_TRANS_ID=AB12-CD34-EF56 ruby script/test_payment_status.rb"
  puts "  rake comgate:test_payment_status TRANS_ID=AB12-CD34-EF56"
  exit 1
end

client = ComgateApi::Client.new
puts "\n🔍 Testing payment_status endpoint..."
puts "🎫 Transaction ID: #{trans_id}"
puts "-" * 60

begin
  status = client.payment_status(trans_id: trans_id)

  puts "✅ Payment status retrieved:\n\n"
  puts "Status: #{status[:status]}"
  puts "Code: #{status[:code]}"
  puts "Message: #{status[:message]}"
  puts "Trans ID: #{status[:transId]}"
  puts "Price: #{status[:price]} #{status[:curr]}"
  puts "Label: #{status[:label]}"
  puts "Ref ID: #{status[:refId]}"
  puts "Email: #{status[:email]}" if status[:email]
  puts "Test: #{status[:test]}"

  if status[:payerName] || status[:payerAcc]
    puts "\nPayer Info:"
    puts "  Name: #{status[:payerName]}" if status[:payerName]
    puts "  Account: #{status[:payerAcc]}" if status[:payerAcc]
  end

  puts "\n📊 Full Response:"
  puts JSON.pretty_generate(status)
rescue ComgateApi::HTTPError => e
  puts "❌ HTTP Error #{e.status}:"
  puts e.body
  begin
    parsed = JSON.parse(e.body, symbolize_names: true)
    puts "\nParsed error:"
    puts "  Code: #{parsed[:code]}"
    puts "  Message: #{parsed[:message]}"
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
