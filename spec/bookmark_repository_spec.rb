module EventFramework
  RSpec.describe BookmarkRepository do
    let(:database) { TestDomain.database(:projections) }

    subject(:bookmark_repository) { described_class.new(name: 'Foo::Bar::Baz', database: database) }

    describe '#checkout' do
      context 'when the bookmark does not exist' do
        it 'returns a bookmark starting a 0 and disabled' do
          bookmark = bookmark_repository.checkout
          sequence, disabled = bookmark.next

          expect(sequence).to eq 0
          expect(disabled).to be true
        end

        it 'inserts a new record into the database' do
          bookmark_repository.checkout

          expect(database[:bookmarks].all).to match [a_hash_including(name: 'Foo::Bar::Baz', sequence: 0)]
        end
      end

      context 'when the bookmark exists' do
        before do
          database[:bookmarks].insert(name: 'Foo::Bar::Baz', sequence: 42)
        end

        it 'returns the bookmark' do
          bookmark = bookmark_repository.checkout
          sequence, _disabled = bookmark.next

          expect(sequence).to eq 42
        end

        context 'when a lock is already taken' do
          before do
            bookmark_repository.checkout
          end

          it 'raises an error' do
            lock_key = database[:bookmarks].first[:lock_key]

            # NOTE: Get a separate database connection
            other_database_connection = Sequel.connect(database.connection_url)
            repository = described_class.new(name: 'Foo::Bar::Baz', database: other_database_connection)

            expect { repository.checkout }
              .to raise_error BookmarkRepository::UnableToCheckoutBookmarkError,
                              "Unable to checkout Foo::Bar::Baz (#{lock_key}); another process is already using this bookmark"
          end
        end
      end

      context 'when the bookmark exists with the wrong module nesting' do
        before do
          # Old modules in bookmark
          database[:bookmarks].insert(name: 'Foo::Baz', sequence: 42)
        end

        it 'returns the bookmark' do
          bookmark = bookmark_repository.checkout
          sequence, _disabled = bookmark.next

          expect(sequence).to eq 42
        end
      end
    end

    describe '#readonly_bookmark' do
      context 'when the bookmark exists' do
        before do
          database[:bookmarks].insert(name: 'Foo::Bar::Baz', lock_key: 1, sequence: 42)
        end

        it 'returns a readonly bookmark' do
          expect(BookmarkReadonly).to receive(:new)
            .with(lock_key: 1, database: database)

          bookmark_repository.readonly_bookmark
        end
      end
    end
  end
end
