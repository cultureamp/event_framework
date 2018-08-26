module EventFramework
  class Bookmark
    def initialize(name:)
      @name = name
    end

    def sequence
      bookmarks_table.select(:sequence).first(name: name)[:sequence]
    end

    def sequence=(value)
      bookmarks_table.where(name: name).update(sequence: value)
    end

    private

    attr_reader :name

    def bookmarks_table
      EventStore.database[:bookmarks]
    end
  end
end
