require 'dry/struct'

module EventFramework
  class DomainEvent < DomainStruct
    def type
      self.class
    end

    # Override this in your subclass to upcast events.
    def upcast(_row)
      self
    end
  end
end
