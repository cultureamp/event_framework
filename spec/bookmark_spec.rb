module EventFramework
  RSpec.describe Bookmark do
    let(:bookmark) do
      bookmark_row = EventStore.database[:bookmarks].returning.insert(name: 'foo', sequence: 42).first
      Bookmark.new(id: bookmark_row[:id])
    end

    describe '#last_processed_event_sequence' do
      it 'returns the sequence' do
        expect(bookmark.last_processed_event_sequence).to eq 42
      end
    end

    describe '#last_processed_event_sequence=' do
      it 'sets the sequence' do
        bookmark.last_processed_event_sequence = 43

        expect(bookmark.last_processed_event_sequence).to eq 43
      end
    end
  end
end
