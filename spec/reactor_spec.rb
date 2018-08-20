module EventFramework
  RSpec.describe Reactor do
    describe '#process_events' do
      let(:events) do
        [
          instance_double(Event, sequence: 1),
          instance_double(Event, sequence: 2),
        ]
      end
      let(:bookmark) { instance_double(Bookmark) }

      subject(:reactor) { described_class.new }

      before do
        allow(reactor).to receive(:bookmark).and_return(bookmark)
        allow(bookmark).to receive(:sequence=)
        allow(reactor).to receive(:handle_event)
        allow(EventStore.database).to receive(:transaction).and_yield
      end

      it 'opens a database transaction for each event' do
        expect(EventStore.database).to receive(:transaction).twice

        reactor.process_events(events)
      end

      it 'calls handle event for each event individually' do
        expect(reactor).to receive(:handle_event).with(events[0])
        expect(reactor).to receive(:handle_event).with(events[1])

        reactor.process_events(events)
      end

      it 'updates the bookmark for each event' do
        expect(bookmark).to receive(:sequence=).with(1)
        expect(bookmark).to receive(:sequence=).with(2)

        reactor.process_events(events)
      end
    end
  end
end
