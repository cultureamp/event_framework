module EventFramework
  RSpec.describe Bookmark do
    let(:bookmark_name) { "BookmarkSpec" }

    let(:bookmark) { Bookmark.new(name: bookmark_name, database: EventFramework.test_database) }

    before do
      EventFramework.test_database[:bookmarks].insert(name: bookmark_name, sequence: 42)
    end

    describe '#sequence' do
      context 'when a bookmark exists for the given name' do
        it 'returns the sequence' do
          expect(bookmark.sequence).to eq 42
        end
      end

      context 'when no bookmark exists for the given name' do
        before do
          EventFramework.test_database[:bookmarks].where(name: bookmark_name).delete
        end

        it 'returns 0' do
          expect(bookmark.sequence).to eq 0
        end
      end
    end

    describe '#sequence=' do
      context 'when the bookmark is not read-only' do
        it 'sets the sequence' do
          bookmark.sequence = 43

          expect(bookmark.sequence).to eq 43
        end
      end

      context 'when the bookmark is read-only' do
        let(:bookmark) { Bookmark.new(name: bookmark_name, database: EventFramework.test_database, read_only: true) }

        it 'raises an error' do
          expect { bookmark.sequence = 43 }.to raise_error(Bookmark::ReadonlyError)
        end
      end
    end
  end
end
