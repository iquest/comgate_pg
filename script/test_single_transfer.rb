#!/usr/bin/env ruby
# frozen_string_literal: true

require "dotenv/load"
require "comgate_api"
require "json"

transfer_id = ARGV[0] || ENV["TRANSFER_ID"]

unless transfer_id
  puts "Error: Transfer ID is required"
  puts "\nUsage:"
  puts "  ruby script/test_single_transfer.rb 1234567"
  puts "  TRANSFER_ID=1234567 ruby script/test_single_transfer.rb"
  puts "  rake comgate:test_single_transfer[1234567]"
  exit 1
end

client = ComgateApi::Client.new
puts "\nTesting single_transfer endpoint..."
puts "Transfer ID: #{transfer_id}"
puts "-" * 60

begin
  transfer = client.single_transfer(transfer_id: transfer_id)

  if transfer.is_a?(Array) && transfer.empty?
    puts "No transfer found for #{transfer_id}"
  elsif transfer.is_a?(Array)
    puts "Found #{transfer.length} transfer record(s):\n\n"
    transfer.each_with_index do |item, idx|
      puts "Transfer ##{idx + 1}:"
      item.each { |key, value| puts "  #{key}: #{value}" }
      puts
    end
  else
    puts "Response:"
    puts "#{transfer.class.name}"
    puts JSON.pretty_generate(transfer)
  end
rescue ComgateApi::HTTPError => e
  puts "HTTP Error #{e.status}:"
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
  puts "Configuration Error: #{e.message}"
  puts "   Please check your .env file with COMGATE_MERCHANT_ID and COMGATE_SECRET"
  exit 1
rescue ArgumentError => e
  puts "Validation Error: #{e.message}"
  exit 1
rescue StandardError => e
  puts "Error: #{e.class} - #{e.message}"
  puts e.backtrace.first(5)
  exit 1
end
