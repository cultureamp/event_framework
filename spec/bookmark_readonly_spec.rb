module EventFramework
  RSpec.describe BookmarkReadonly do
    let(:database) { TestDomain.database(:projections) }
    let(:bookmark) { described_class.new(name: 'foo', database: database) }

    before do
      database[:bookmarks].insert(name: 'foo', sequence: 42)
    end

    describe '#sequence' do
      it 'returns the sequence' do
        expect(bookmark.sequence).to eq 42
      end
    end
  end
end
