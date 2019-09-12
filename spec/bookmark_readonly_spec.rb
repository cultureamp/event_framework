module EventFramework
  RSpec.describe BookmarkReadonly do
    let(:database) { TestDomain.database(:projections) }
    let(:bookmark) { described_class.new(lock_key: 1, database: database) }

    before do
      database[:bookmarks].insert(name: 'foo', lock_key: 1, sequence: 42)
    end

    describe '#sequence' do
      it 'returns the sequence' do
        expect(bookmark.sequence).to eq 42
      end
    end
  end
end
