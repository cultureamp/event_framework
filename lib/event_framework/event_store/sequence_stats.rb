module EventFramework
  module EventStore
    class SequenceStats
      class << self
        def all(database: EventStore.database)
          database[:events_sequence_stats].all
        end

        def refresh(database: EventStore.database)
          database.refresh_view(:events_sequence_stats)
        end
      end
    end
  end
end
