module EventFramework
  class BookmarkRepository
    UnableToCheckoutBookmarkError = Class.new(Error)

    class << self
      def checkout(name:)
        id = find_id(name)

        unless can_lock?(id)
          raise UnableToCheckoutBookmarkError, "Unable to checkout #{name} (#{id}); " \
            "another process is already using this bookmark"
        end

        Bookmark.new(id: id)
      end

      private

      def can_lock?(id)
        database.select(Sequel.function(:pg_try_advisory_lock, id)).first[:pg_try_advisory_lock]
      end

      def find_id(name)
        bookmark_row = database[:bookmarks].select(:id).first(name: name)

        if bookmark_row
          bookmark_row[:id]
        else
          database[:bookmarks].returning.insert(name: name, sequence: 0).first[:id]
        end
      end

      def database
        EventStore.database
      end
    end
  end
end
