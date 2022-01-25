module EventFramework
  class Bookmark
    def initialize(lock_key:, database:)
      @lock_key = lock_key
      @bookmarks_table = database[:bookmarks]
      @database = database
    end

    def next
      bookmarks_table.select(:sequence, :disabled).first(lock_key: lock_key).values
    end

    def sequence=(value)
      bookmarks_table.where(lock_key: lock_key).update(sequence: value)
    end

    def transaction(**args)
      database.transaction(**args) { yield }
    end

    private

    attr_reader :lock_key, :bookmarks_table, :database
  end
end
