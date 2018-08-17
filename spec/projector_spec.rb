module EventFramework
  RSpec.describe Projector do
    describe '#process_events' do
      let(:event) { instance_double(Event) }

      it 'opens a single database transaction for all events' do
        expect(EventStore.database).to receive(:transaction).once

        described_class.new.process_events([event])
      end

      it 'updates the bookmark'
    end
  end
end
