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
      bookmark = find_bookmark || construct_new_bookmark
      lock_result = try_lock(bookmark[:lock_key])

      unless locked?(lock_result)
        raise UnableToCheckoutBookmarkError, "Unable to checkout #{name} (#{bookmark[:lock_key]}); " \
          "another process is already using this bookmark"
      end
    end

    def try_lock(lock_key)
      database.select(Sequel.function(:pg_try_advisory_lock, lock_key))
    end

    def locked?(lock_result)
      lock_result.first[:pg_try_advisory_lock]
    end

    def find_bookmark
      database[:bookmarks].select(:lock_key).first(name: name)
    end

    def construct_new_bookmark
      database[:bookmarks].returning.insert(name: name, sequence: 0).first
    end
  end
end
