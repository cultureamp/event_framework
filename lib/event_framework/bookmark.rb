module EventFramework
  class Bookmark
    def initialize(name:, bookmarks_table: EventStore.database[:bookmarks])
      @name = name
      @bookmarks_table = bookmarks_table
    end

    def sequence
      bookmarks_table.select(:sequence).first(name: name)[:sequence]
    end

    def sequence=(value)
      bookmarks_table.where(name: name).update(sequence: value)
    end

    private

    attr_reader :name, :bookmarks_table
  end
end
