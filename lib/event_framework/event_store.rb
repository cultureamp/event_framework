require "sequel"
require "erb"
require "yaml"

module EventFramework
  module EventStore
    autoload :EventBuilder, "event_framework/event_store/event_builder"
    autoload :EventTypeResolver, "event_framework/event_store/event_type_resolver"
    autoload :SequenceStats, "event_framework/event_store/sequence_stats"
    autoload :Sink, "event_framework/event_store/sink"
    autoload :Source, "event_framework/event_store/source"
  end
end
