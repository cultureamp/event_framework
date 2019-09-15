module EventFramework
  class Bookmark
    def initialize(lock_key:, database:)
      @lock_key = lock_key
      @bookmarks_table = database[:bookmarks]
    end

    def next
      bookmarks_table.select(:sequence, :disabled).first(lock_key: lock_key).values
    end

    def sequence=(value)
      bookmarks_table.where(lock_key: lock_key).update(sequence: value)
    end

    private

    attr_reader :lock_key, :bookmarks_table
  end
end
