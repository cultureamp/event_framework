module EventFramework
  class BookmarkReadonly
    def initialize(name:, database:)
      @name = name
      @bookmarks_table = database[:bookmarks]
    end

    def sequence
      row = bookmarks_table.select(:sequence).first(name: name)
      row.nil? ? 0 : row[:sequence]
    end

    private

    attr_reader :name, :bookmarks_table
  end
end
