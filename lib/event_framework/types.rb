require "dry/types"
require "dry/types/version"

module EventFramework
  module Types
    if Gem::Version.new(Dry::Types::VERSION) > Gem::Version.new("1.0")
      include Dry.Types
    else
      include Dry::Types.module
    end

    # Note; this is _not_ a RFC-compliant UUID; there's a lot of data in
    # Murmur (and other systems) that contain data that _looks_ like UUIDs,
    # but is actually just a big random number in base16 with dashes in the
    # right places.
    UUID_REGEX = /
      \A[0-9a-fA-F]{8}
      -[0-9a-fA-F]{4}
      -[0-9a-fA-F]{4}
      -[0-9a-fA-F]{4}
      -[0-9a-fA-F]{12}\z
    /ix

    UUID = Strict::String.constrained(format: UUID_REGEX)

    # This _is_ a RFC-compliant UUID-v4
    UUID_V4_REGEX = /
      \A[0-9a-fA-F]{8}
      -[0-9a-fA-F]{4}
      -4[0-9a-fA-F]{3}
      -[89abAB][0-9a-fA-F]{3}
      -[0-9a-fA-F]{12}\z
    /ix

    UUID_V4 = Strict::String.constrained(format: UUID_V4_REGEX)
  end
end
