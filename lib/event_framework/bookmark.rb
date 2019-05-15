module EventFramework
  class Bookmark
    def initialize(name:, database:)
      @name = name
      @bookmarks_table = database[:bookmarks]
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
