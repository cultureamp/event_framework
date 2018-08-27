module EventFramework
  class BookmarkRepository
    UnableToCheckoutBookmarkError = Class.new(Error)

    def initialize(name:, database: EventStore.database)
      @name = name
      @database = database
    end

    def checkout
      acquire_lock

      Bookmark.new(name: name)
    end

    private

    attr_reader :database, :name

    def acquire_lock
      lock_key = find_lock_key
      lock = Sequel.function(:pg_try_advisory_lock, lock_key)

      unless is_locked?(lock)
        raise UnableToCheckoutBookmarkError, "Unable to checkout #{name} (#{lock_key}); " \
          "another process is already using this bookmark"
      end
    end

    def is_locked?(lock)
      database.select(lock).first[:pg_try_advisory_lock]
    end

    def find_lock_key
      bookmark_row = database[:bookmarks].select(:lock_key).first(name: name)

      if bookmark_row
        bookmark_row[:lock_key]
      else
        database[:bookmarks].returning.insert(name: name, sequence: 0).first[:lock_key]
      end
    end
  end
end
