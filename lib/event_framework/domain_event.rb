require "dry/struct"

module EventFramework
  class DomainEvent < DomainStruct
    def type
      self.class
    end

    class << self
      # Use this to upcast your events
      #
      # upcast do |row|
      #   row.merge(foo: 'bar')
      # end
      def upcast(&block)
        @upcast_block = block
      end

      def upcast_row(row)
        return row unless @upcast_block

        @upcast_block.call(row)
      end
    end
  end
end
