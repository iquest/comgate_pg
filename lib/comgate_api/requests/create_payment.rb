# frozen_string_literal: true

require "dry-struct"
require_relative "../types"

module ComgateApi
  module Requests
    class CreatePayment < Dry::Struct
      transform_keys(&:to_sym)

      # Required attributes
      attribute :price, Types::MinPrice
      attribute :curr, Types::Coercible::String  # API validates currency codes
      attribute :label, Types::Label
      attribute :refId, Types::Coercible::String

      # Optional - one of email or phone required (validated separately)
      attribute? :email, Types::Coercible::String.optional
      attribute? :phone, Types::Coercible::String.optional
      attribute? :fullName, Types::Coercible::String.optional

      # Payment configuration
      attribute? :test, Types::Bool.optional
      attribute? :method, Types::Coercible::String.optional
      attribute? :account, Types::Coercible::String.optional
      attribute? :country, Types::Coercible::String.optional  # API validates country codes

      # Billing address
      attribute? :billingAddrCity, Types::Coercible::String.optional
      attribute? :billingAddrStreet, Types::Coercible::String.optional
      attribute? :billingAddrPostalCode, Types::Coercible::String.optional
      attribute? :billingAddrCountry, Types::Coercible::String.optional

      # Delivery
      attribute? :delivery, Types::Coercible::String.optional  # API validates delivery types
      attribute? :homeDeliveryCity, Types::Coercible::String.optional
      attribute? :homeDeliveryStreet, Types::Coercible::String.optional
      attribute? :homeDeliveryPostalCode, Types::Coercible::String.optional
      attribute? :homeDeliveryCountry, Types::Coercible::String.optional

      # Product information
      attribute? :category, Types::Coercible::String.optional  # API validates categories
      attribute? :name, Types::Coercible::String.optional
      attribute? :lang, Types::Coercible::String.optional  # API validates language codes

      # Payment types
      attribute? :preauth, Types::Bool.optional
      attribute? :initRecurring, Types::Bool.optional
      attribute? :verification, Types::Bool.optional

      # Expiration
      attribute? :expirationTime, Types::Coercible::String.optional
      attribute? :dynamicExpiration, Types::Bool.optional

      # Callback URLs
      attribute? :url_paid, Types::Coercible::String.optional
      attribute? :url_cancelled, Types::Coercible::String.optional
      attribute? :url_pending, Types::Coercible::String.optional

      # Fee configuration
      attribute? :chargeUnregulatedCardFees, Types::Bool.optional
      attribute? :enableApplePayGooglePay, Types::Bool.optional

      def self.from_snake_case(**attrs)
        # Convert snake_case parameter names to camelCase for API
        normalized = {}
        attrs.each do |key, value|
          api_key = case key.to_sym
                    when :ref_id then :refId
                    when :full_name then :fullName
                    when :billing_addr_city then :billingAddrCity
                    when :billing_addr_street then :billingAddrStreet
                    when :billing_addr_postal_code then :billingAddrPostalCode
                    when :billing_addr_country then :billingAddrCountry
                    when :home_delivery_city then :homeDeliveryCity
                    when :home_delivery_street then :homeDeliveryStreet
                    when :home_delivery_postal_code then :homeDeliveryPostalCode
                    when :home_delivery_country then :homeDeliveryCountry
                    when :init_recurring then :initRecurring
                    when :expiration_time then :expirationTime
                    when :dynamic_expiration then :dynamicExpiration
                    when :charge_unregulated_card_fees then :chargeUnregulatedCardFees
                    when :enable_apple_pay_google_pay then :enableApplePayGooglePay
                    else key.to_sym
                    end
          normalized[api_key] = value
        end
        new(**normalized)
      end

      def validate!
        # Check either email or phone is provided
        if email.nil? && phone.nil?
          raise ArgumentError, "Either email or phone must be provided"
        end

        # Validate home delivery address if delivery type is HOME_DELIVERY
        if delivery == "HOME_DELIVERY"
          required_fields = {
            homeDeliveryCity: "home_delivery_city",
            homeDeliveryStreet: "home_delivery_street",
            homeDeliveryPostalCode: "home_delivery_postal_code",
            homeDeliveryCountry: "home_delivery_country"
          }

          missing = required_fields.select { |attr, _| send(attr).nil? || send(attr).to_s.strip.empty? }
          if missing.any?
            field_names = missing.values.join(", ")
            raise ArgumentError, "HOME_DELIVERY requires: #{field_names}"
          end
        end

        # Basic format validation for expiration time if provided
        if expirationTime && !expirationTime.match?(/^\d+[mhd]$/)
          raise ArgumentError, "expirationTime must be in format: number + unit (m/h/d), e.g., '30m', '10h', '2d'"
        end

        self
      end

      def to_payload
        # Return hash with only non-nil values for API request
        to_h.compact
      end
    end
  end
end
