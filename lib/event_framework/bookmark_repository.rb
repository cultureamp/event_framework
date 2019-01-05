module EventFramework
  class BookmarkRepository
    UnableToCheckoutBookmarkError = Class.new(Error)

    def initialize(database:)
      @database = database
      @bookmarks = {}
    end

    def query(name)
      find_bookmark(name) || construct_new_bookmark(name)

      Bookmark.new(name: name, database: database, read_only: true)
    end

    def checkout(name)
      @bookmarks[name] ||= begin
        acquire_lock(name)

        Bookmark.new(name: name, database: database)
      end
    end

    private

    attr_reader :database, :name

    def acquire_lock(name)
      bookmark_record = find_bookmark(name) || construct_new_bookmark(name)
      lock_result = try_lock(bookmark_record[:lock_key])

      unless locked?(lock_result)
        raise UnableToCheckoutBookmarkError, "Unable to checkout #{name} (#{bookmark_record[:lock_key]}); " \
          "another process is already using this bookmark"
      end
    end

    def try_lock(lock_key)
      database.select(Sequel.function(:pg_try_advisory_lock, lock_key)).first
    end

    def locked?(lock_result)
      lock_result[:pg_try_advisory_lock]
    end

    def find_bookmark(name)
      database[:bookmarks].select(:lock_key).first(name: name)
    end

    def construct_new_bookmark(name)
      database[:bookmarks].returning.insert(name: name, sequence: 0).first
    end
  end
end
