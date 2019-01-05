module EventFramework
  RSpec.describe BookmarkRepository do
    let(:database) { EventFramework.test_database }
    let(:bookmark_name) { "BookmarkName" }

    subject(:bookmark_repository) do
      described_class.new(database: database)
    end

    shared_examples 'bookmark creation and loading' do
      context 'when the bookmark does not exist' do
        before do
          database[:bookmarks].where(name: bookmark_name).delete
        end

        it 'returns a bookmark starting a 0' do
          expect(bookmark.sequence).to eq 0
          expect(database[:bookmarks].all).to match [a_hash_including(name: bookmark_name, sequence: 0)]
        end
      end

      context 'when the bookmark exists' do
        before do
          database[:bookmarks].insert(name: bookmark_name, sequence: 42)
        end

        it 'returns a bookmark for the given name' do
          expect(bookmark.sequence).to eq 42
        end
      end
    end

    describe '#query' do
      def bookmark
        bookmark_repository.query(bookmark_name)
      end

      it 'returns a read-only bookmark' do
        expect(bookmark).to be_read_only
      end

      include_examples 'bookmark creation and loading'
    end

    describe '#checkout' do
      def bookmark
        bookmark_repository.checkout(bookmark_name)
      end

      it 'returns a writable bookmark' do
        expect(bookmark).not_to be_read_only
      end

      include_examples 'bookmark creation and loading'

      context 'when a lock is already taken' do
        before do
          bookmark_repository.checkout(bookmark_name)
        end

        it 'raises an error' do
          lock_key = database[:bookmarks].first[:lock_key]

          # NOTE: Get a separate database connection
          other_database_connection = Sequel.connect(RSpec.configuration.database_url)

          other_repository = described_class.new(database: other_database_connection)

          expect { other_repository.checkout(bookmark_name) }
            .to raise_error BookmarkRepository::UnableToCheckoutBookmarkError,
                            "Unable to checkout #{bookmark_name} (#{lock_key}); another process is already using this bookmark"
        end
      end
    end
  end
end
