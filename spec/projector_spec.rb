module EventFramework
  RSpec.describe Projector do
    describe '#process_events' do
      let(:events) do
        [
          instance_double(Event, sequence: 2),
          instance_double(Event, sequence: 1),
        ]
      end
      let(:bookmark) { instance_double(Bookmark) }

      subject(:projector) { described_class.new }

      before do
        allow(projector).to receive(:bookmark).and_return(bookmark)
        allow(bookmark).to receive(:sequence=)
        allow(projector).to receive(:handle_event)
        allow(EventStore.database).to receive(:transaction).and_yield
      end

      it 'opens a single database transaction for all events' do
        expect(EventStore.database).to receive(:transaction).once

        projector.process_events(events)
      end

      it 'calls handle event for each event individually' do
        expect(projector).to receive(:handle_event).with(events[0])
        expect(projector).to receive(:handle_event).with(events[1])

        projector.process_events(events)
      end

      it 'updates the bookmark once at the end' do
        expect(bookmark).to receive(:sequence=).with(2)

        projector.process_events(events)
      end
    end
  end
end
