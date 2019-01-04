module EventFramework
  RSpec.describe Bookmark do
    let(:bookmarks_table) { EventFramework.test_database[:bookmarks] }
    let(:bookmark) { Bookmark.new(name: 'foo', bookmarks_table: bookmarks_table) }

    before do
      bookmarks_table.insert(name: 'foo', sequence: 42)
    end

    describe '#sequence' do
      it 'returns the sequence' do
        expect(bookmark.sequence).to eq 42
      end
    end

    describe '#sequence=' do
      it 'sets the sequence' do
        bookmark.sequence = 43

        expect(bookmark.sequence).to eq 43
      end
    end
  end
end
