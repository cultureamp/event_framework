module EventFramework
  RSpec.describe Bookmark do
    let(:bookmark) do
      Bookmark.new(name: 'foo')
    end

    before do
      EventStore.database[:bookmarks].insert(name: 'foo', sequence: 42)
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
