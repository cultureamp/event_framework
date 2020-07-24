require "dry/struct"
require "dry/struct/version"

module EventFramework
  class DomainStruct < Dry::Struct
    transform_keys(&:to_sym)

    if Gem::Version.new(Dry::Struct::VERSION) > Gem::Version.new("1.0")
      schema schema.strict
    else
      input input.strict
    end
  end
end
