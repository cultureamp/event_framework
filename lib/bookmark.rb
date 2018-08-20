module EventFramework
  class Bookmark
    def initialize(id:)
      @id = id
    end

    def sequence
      bookmarks_table.select(:sequence).first(id: id)[:sequence]
    end

    def sequence=(value)
      bookmarks_table.where(id: id).update(sequence: value)
    end

    private

    attr_reader :id

    def bookmarks_table
      EventStore.database[:bookmarks]
    end
  end
end
