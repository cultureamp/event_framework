require 'dry/struct'

module EventFramework
  class DomainEvent < DomainStruct
    def type
      self.class
    end
  end
end
