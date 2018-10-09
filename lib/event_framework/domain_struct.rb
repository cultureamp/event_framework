require 'dry/struct'

module EventFramework
  class DomainStruct < Dry::Struct
    transform_keys(&:to_sym)
    input input.strict
  end
end
