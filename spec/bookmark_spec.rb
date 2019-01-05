module EventFramework
  RSpec.describe Bookmark do
    let(:database) { EventFramework.test_database }
    let(:bookmark_name) { "BookmarkSpec" }

    let(:bookmark) { Bookmark.new(name: bookmark_name, database: database) }

    before do
      database[:bookmarks].insert(name: bookmark_name, sequence: 42)
    end

    describe '#sequence' do
      context 'when a bookmark exists for the given name' do
        it 'returns the sequence' do
          expect(bookmark.sequence).to eq 42
        end
      end

      context 'when no bookmark exists for the given name' do
        before do
          database[:bookmarks].where(name: bookmark_name).delete
        end

        it 'raises an error' do
          expect { bookmark.sequence }.to raise_error(Bookmark::NoRecordError)
        end
      end
    end

    describe '#sequence=' do
      context 'when the bookmark is not read-only' do
        it 'sets the sequence in the database' do
          bookmark.sequence = 43

          expect(database[:bookmarks].where(name: bookmark_name).first[:sequence]).to eql 43
        end
      end

      context 'when the bookmark is read-only' do
        let(:bookmark) { Bookmark.new(name: bookmark_name, database: database, read_only: true) }

        it 'raises an error' do
          expect { bookmark.sequence = 43 }.to raise_error(Bookmark::ReadonlyError)
        end
      end
    end
  end
end
