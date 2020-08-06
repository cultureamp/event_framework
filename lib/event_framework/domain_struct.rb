require "dry/struct"
require "dry/struct/version"

module EventFramework
  class DomainStruct < Dry::Struct
    transform_keys(&:to_sym)

    schema schema.strict
  end
end
