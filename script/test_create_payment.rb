#!/usr/bin/env ruby
# frozen_string_literal: true

require 'dotenv/load'
require 'comgate_api'

client = ComgateApi::Client.new

begin
  response = client.create_payment(
    price: 100,  # 1 CZK minimum (in haléřích/cents)
    curr: 'CZK',
    label: 'paytest',
    ref_id: "1-#{Time.now.to_i}",
    method: 'ALL',
    email: 'juklik@iquest.cz',
    fullName: 'Test User',
    test: true
  )

  puts "✅ Payment created successfully!"
  puts "Code: #{response[:code]}"
  puts "Message: #{response[:message]}"
  puts "Trans ID: #{response[:transId]}"
  puts "Redirect: #{response[:redirect]}"
rescue ComgateApi::HTTPError => e
  puts "❌ HTTP Error #{e.status}:"
  puts e.body

  # Try to parse if JSON
  begin
    parsed = JSON.parse(e.body, symbolize_names: true)
    puts "\nParsed error:"
    puts "  Code: #{parsed[:code]}"
    puts "  Message: #{parsed[:message]}"
  rescue
    # Not JSON, already printed raw body
  end
rescue ComgateApi::ConfigurationError => e
  puts "❌ Configuration Error: #{e.message}"
rescue StandardError => e
  puts "❌ Error: #{e.class} - #{e.message}"
  puts e.backtrace.first(5)
end
