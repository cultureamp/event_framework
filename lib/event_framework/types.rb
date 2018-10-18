require 'dry/struct'

module EventFramework
  module Types
    include Dry::Types.module

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
  end
end
