module EventFramework
  RSpec.describe Bookmark do
    let(:bookmark) do
      bookmark_row = EventStore.database[:bookmarks].returning.insert(name: 'foo', sequence: 42).first
      Bookmark.new(id: bookmark_row[:id])
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
