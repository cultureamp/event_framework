module EventFramework
  module Tracer
    class NullTracer
      def trace(_span_label, resource:)
        yield(NullSpan.new)
      end
    end

    class NullSpan
      def set_tag(_tag_label, _value)
        # no op
      end
    end
  end
end
