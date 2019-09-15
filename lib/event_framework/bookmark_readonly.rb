module EventFramework
  class BookmarkReadonly
    def initialize(lock_key:, database:)
      @lock_key = lock_key
      @bookmarks_table = database[:bookmarks]
    end

    def sequence
      row = bookmarks_table.select(:sequence).first(lock_key: lock_key)
      row.nil? ? 0 : row[:sequence]
    end

    private

    attr_reader :lock_key, :bookmarks_table
  end
end
