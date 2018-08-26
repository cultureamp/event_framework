module EventFramework
  class BookmarkRepository
    UnableToCheckoutBookmarkError = Class.new(Error)

    class << self
      def checkout(name:)
        lock_key = find_lock_key(name)

        unless can_lock?(lock_key)
          raise UnableToCheckoutBookmarkError, "Unable to checkout #{name} (#{lock_key}); " \
            "another process is already using this bookmark"
        end

        Bookmark.new(name: name)
      end

      private

      def can_lock?(lock_key)
        database.select(Sequel.function(:pg_try_advisory_lock, lock_key)).first[:pg_try_advisory_lock]
      end

      def find_lock_key(name)
        bookmark_row = database[:bookmarks].select(:lock_key).first(name: name)

        if bookmark_row
          bookmark_row[:lock_key]
        else
          database[:bookmarks].returning.insert(name: name, sequence: 0).first[:lock_key]
        end
      end

      def database
        EventStore.database
      end
    end
  end
end
