require 'dry/struct'

module EventFramework
  class DomainEvent < Dry::Struct
    transform_keys(&:to_sym)

    def type
      self.class
    end
  end
end
