module EventFramework
  class Bookmark
    def initialize(id:)
      @id = id
    end

    def last_processed_event_sequence
      bookmarks_table.select(:sequence).first(id: id)[:sequence]
    end

    def last_processed_event_sequence=(sequence)
      bookmarks_table.where(id: id).update(sequence: sequence)
    end

    private

    attr_reader :id

    def bookmarks_table
      EventStore.database[:bookmarks]
    end
  end
end
