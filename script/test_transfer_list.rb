#!/usr/bin/env ruby
# frozen_string_literal: true

require "dotenv/load"
require "comgate_api"
require "date"
require "json"

# Accept date from command line argument or environment variable
date = ARGV[0] || Date.today.strftime("%Y-%m-%d")

client = ComgateApi::Client.new
puts "\n🔍 Testing transfer_list endpoint..."
puts "📅 Date: #{date}"
puts "-" * 60

begin
  transfers = client.transfer_list(date: date)

  if transfers.is_a?(Array) && transfers.empty?
    puts "⚠️  No transfers found for #{date}"
  elsif transfers.is_a?(Array)
    puts "✅ Found #{transfers.length} transfer(s):\n\n"
    transfers.each_with_index do |transfer, idx|
      puts "Transfer ##{idx + 1}:"
      transfer.each { |key, value| puts "  #{key}: #{value}" }
      puts
    end
  else
    puts "📊 Response:"
    puts "#{transfers.class.name}"
    puts JSON.pretty_generate(transfers)
  end
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
rescue StandardError => e
  puts "❌ Error: #{e.class} - #{e.message}"
  puts e.backtrace.first(5)
  exit 1
end
