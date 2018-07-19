require 'dry/struct'

module EventFramework
  module Types
    include Dry::Types.module

    UUID_REGEX = /
      \A[0-9a-fA-F]{8}
      -[0-9a-fA-F]{4}
      -4[0-9a-fA-F]{3}
      -[89abAB][0-9a-fA-F]{3}
      -[0-9a-fA-F]{12}\z
    /ix

    # See: https://github.com/Carburetor/carb-types/blob/0dbe462bc8aaf8e2253787aec722a6943bf01e2f/lib/carb/types/uuid.rb
    UUID = Strict::String.constrained(format: UUID_REGEX)
  end
end
