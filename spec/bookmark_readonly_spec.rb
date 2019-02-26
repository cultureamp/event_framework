module EventFramework
  RSpec.describe BookmarkReadonly do
    let(:bookmarks_table) { EventStore.database[:bookmarks] }
    let(:bookmark) { Bookmark.new(name: 'foo', bookmarks_table: bookmarks_table) }

    before do
      bookmarks_table.insert(name: 'foo', sequence: 42)
    end

    describe '#sequence' do
      it 'returns the sequence' do
        expect(bookmark.sequence).to eq 42
      end
    end
  end
end
