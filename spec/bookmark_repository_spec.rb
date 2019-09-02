module EventFramework
  RSpec.describe BookmarkRepository do
    let(:database) { TestDomain.database(:projections) }

    subject(:bookmark_repository) { described_class.new(name: 'foo', database: database) }

    describe '#checkout' do
      context 'when the bookmark does not exist' do
        it 'returns a bookmark starting a 0' do
          bookmark = bookmark_repository.checkout

          expect(bookmark.sequence).to eq 0
        end

        it 'inserts a new record into the database' do
          bookmark_repository.checkout

          expect(database[:bookmarks].all).to match [a_hash_including(name: 'foo', sequence: 0)]
        end
      end

      context 'when the bookmark exists' do
        before do
          database[:bookmarks].insert(name: 'foo', sequence: 42)
        end

        it 'returns the bookmark' do
          bookmark = bookmark_repository.checkout

          expect(bookmark.sequence).to eq 42
        end

        context 'when a lock is already taken' do
          before do
            bookmark_repository.checkout
          end

          it 'raises an error' do
            lock_key = database[:bookmarks].first[:lock_key]

            # NOTE: Get a separate database connection
            other_database_connection = Sequel.connect(database.connection_url)
            repository = described_class.new(name: 'foo', database: other_database_connection)

            expect { repository.checkout }
              .to raise_error BookmarkRepository::UnableToCheckoutBookmarkError,
                              "Unable to checkout foo (#{lock_key}); another process is already using this bookmark"
          end
        end
      end
    end
  end
end
