module EventFramework
  RSpec.describe BookmarkRepository do
    describe '.get_lock' do
      context 'when the bookmark does not exist' do
        it 'returns a bookmark starting a 0' do
          bookmark = described_class.get_lock(name: 'foo')

          expect(bookmark.sequence).to eq 0
        end

        it 'inserts a new record into the database' do
          described_class.get_lock(name: 'foo')

          expect(EventStore.database[:bookmarks].all).to match [a_hash_including(name: 'foo', sequence: 0)]
        end
      end

      context 'when the bookmark exists' do
        before do
          EventStore.database[:bookmarks].insert(name: 'foo', sequence: 42)
        end

        it 'returns the bookmark' do
          bookmark = described_class.get_lock(name: 'foo')

          expect(bookmark.sequence).to eq 42
        end

        context 'when a lock is already taken' do
          before do
            described_class.get_lock(name: 'foo')
          end

          it 'raises an error' do
            begin
              id = EventStore.database[:bookmarks].first[:id]

              # Note: Get a separate database connection
              other_database_connection = Sequel.connect(EventFramework.config.database_url)
              allow(described_class).to receive(:database).and_return(other_database_connection)

              expect { described_class.get_lock(name: 'foo') }
                .to raise_error BookmarkRepository::UnableToLockError, "Unable to get a lock on foo (#{id})"
            ensure
              # NOTE: Clean up the separate databse connection so
              # DatabaseCleaner doesn't try to clean it.
              other_database_connection.disconnect
              Sequel.synchronize { ::Sequel::DATABASES.delete(other_database_connection) }
            end
          end
        end
      end
    end
  end
end
