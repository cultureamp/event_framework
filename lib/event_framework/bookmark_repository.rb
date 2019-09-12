module EventFramework
  class BookmarkRepository
    UnableToCheckoutBookmarkError = Class.new(Error)

    def initialize(name:, database:)
      @name = name
      @database = database
    end

    def checkout
      lock_key = acquire_lock

      Bookmark.new(lock_key: lock_key, database: database)
    end

    def readonly_bookmark
      bookmark = find_bookmark

      BookmarkReadonly.new(lock_key: bookmark[:lock_key], database: database)
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

      bookmark[:lock_key]
    end

    def try_lock(lock_key)
      database.select(Sequel.function(:pg_try_advisory_lock, lock_key)).first
    end

    def locked?(lock_result)
      lock_result[:pg_try_advisory_lock]
    end

    def find_bookmark
      name_final_part = name.split("::").last
      database[:bookmarks].select(:lock_key).first(Sequel.like(:name, "%::#{name_final_part}"))
    end

    def construct_new_bookmark
      database[:bookmarks].returning.insert(name: name, sequence: 0).first
    end
  end
end
