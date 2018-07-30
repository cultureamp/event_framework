require 'dry/struct'

module EventFramework
  class Command < Dry::Struct
    transform_keys(&:to_sym)
  end
end
