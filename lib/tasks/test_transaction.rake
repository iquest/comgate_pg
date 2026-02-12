# frozen_string_literal: true

namespace :comgate do
  desc "Test create_payment endpoint"
  task :test_create_payment do
    puts "\n" + "=" * 60
    puts "🚀 Comgate API: create_payment test"
    puts "=" * 60

    script_path = File.expand_path("../../script/test_create_payment.rb", __dir__)
    system("ruby #{script_path}")
    exit $?.exitstatus
  end

  desc "Test payment_status endpoint (requires TRANS_ID)"
  task :test_payment_status, [:trans_id] do |_t, args|
    trans_id = args[:trans_id]

    puts "\n" + "=" * 60
    puts "🚀 Comgate API: payment_status test"
    puts "=" * 60

    script_path = File.expand_path("../../script/test_payment_status.rb", __dir__)

    if trans_id
      system("ruby #{script_path} #{trans_id}")
    else
      system("ruby #{script_path}")
    end
    exit $?.exitstatus
  end

  desc "Test cancel_payment endpoint (requires TRANS_ID)"
  task :test_cancel_payment, [:trans_id] do |_t, args|
    trans_id = args[:trans_id]

    puts "\n" + "=" * 60
    puts "🚀 Comgate API: cancel_payment test"
    puts "=" * 60

    script_path = File.expand_path("../../script/test_cancel_payment.rb", __dir__)

    if trans_id
      system("ruby #{script_path} #{trans_id}")
    else
      system("ruby #{script_path}")
    end
    exit $?.exitstatus
  end

  desc "Test transfer_list endpoint (optional: COMGATE_TEST_DATE=YYYY-MM-DD)"
  task :test_transfer_list, [:date] do |_t, args|
    puts "\n" + "=" * 60
    puts "🚀 Comgate API: transfer_list test"
    puts "=" * 60

    script_path = File.expand_path("../../script/test_transfer_list.rb", __dir__)
    date = args[:date]
    if date && !date.to_s.strip.empty?
      system("ruby #{script_path} #{date}")
    else
      system("ruby #{script_path}")
    end
    exit $?.exitstatus
  end

  desc "Test single_transfer endpoint (requires TRANSFER_ID)"
  task :test_single_transfer, [:transfer_id] do |_t, args|
    transfer_id = args[:transfer_id] || ENV["TRANSFER_ID"]

    puts "\n" + "=" * 60
    puts "🚀 Comgate API: single_transfer test"
    puts "=" * 60

    script_path = File.expand_path("../../script/test_single_transfer.rb", __dir__)

    if transfer_id
      system("ruby #{script_path} #{transfer_id}")
    else
      system("ruby #{script_path}")
    end
    exit $?.exitstatus
  end

  # Alias for backward compatibility
  task test_transfers: :test_transfer_list

  desc "List all available Comgate API test tasks"
  task :list do
    puts "\n📋 Available Comgate API test tasks:\n\n"
    puts "  rake comgate:test_create_payment"
    puts "    → Test payment creation (uses test mode)"
    puts "\n  rake comgate:test_payment_status TRANS_ID=AB12-CD34-EF56"
    puts "    → Check payment status by transaction ID"
    puts "\n  rake comgate:test_cancel_payment TRANS_ID=AB12-CD34-EF56"
    puts "    → Cancel a pending payment"
    puts "\n  rake comgate:test_transfer_list [COMGATE_TEST_DATE=YYYY-MM-DD]"
    puts "    → List transfers for a specific date (default: today)"
    puts "\n  rake comgate:test_single_transfer[1234567]"
    puts "    → Show details for a specific transfer ID"
    puts "\n💡 All tasks require COMGATE_MERCHANT_ID and COMGATE_SECRET in .env"
    puts ""
  end
end
