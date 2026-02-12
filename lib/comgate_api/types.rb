# frozen_string_literal: true

require "dry-types"

module ComgateApi
  module Types
    include Dry.Types()

    # Basic type constraints - API will validate specific enum values
    # This keeps the gem simple and maintainable

    # Label: 1-16 characters required by API
    Label = String.constrained(min_size: 1, max_size: 16)

    # Price: minimum 100 haléř (1 CZK) as general constraint
    # API will enforce currency-specific minimums
    MinPrice = Coercible::Integer.constrained(gteq: 100)

    # Date format YYYY-MM-DD
    DateString = String.constrained(format: /^\d{4}-\d{2}-\d{2}$/)

    # Expiration time format
    ExpirationTime = String.constrained(format: /^\d+[mhd]$/)

    # URL format
    URL = String.constrained(format: /^https?:\/\//)
  end
end
