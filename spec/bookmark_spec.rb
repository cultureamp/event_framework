module EventFramework
  RSpec.describe Bookmark do
    let(:database) { TestDomain.database(:projections) }
    let(:bookmark) { described_class.new(name: 'foo', database: database) }

    before do
      database[:bookmarks].insert(name: 'foo', sequence: 42)
    end

    describe '#next' do
      it 'returns the sequence and disabled state' do
        sequence, disabled = bookmark.next
        expect(sequence).to eq 42
        expect(disabled).to be true
      end
    end

    describe '#sequence=' do
      it 'sets the sequence' do
        bookmark.sequence = 43

        sequence, _disabled = bookmark.next
        expect(sequence).to eq 43
      end
    end
  end
end
