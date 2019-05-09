module EventFramework
  RSpec.describe BookmarkReadonly do
    let(:bookmarks_table) { EventFramework.test_database[:bookmarks] }
    let(:bookmark) { described_class.new(name: 'foo', bookmarks_table: bookmarks_table) }

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
