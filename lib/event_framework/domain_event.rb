require 'dry/struct'

module EventFramework
  class DomainEvent < DomainStruct
    def type
      self.class
    end

    class << self
      # Override this in your subclass to upcast events.
      def upcast(row)
        row
      end
    end
  end
end
