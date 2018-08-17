module EventFramework
  RSpec.describe Reactor do
    describe '#process_events' do
      let(:event) { instance_double(Event) }

      it 'opens a database transaction for each event' do
        expect(EventStore.database).to receive(:transaction).twice

        described_class.new.process_events([event, event])
      end

      it 'updates the bookmark'
    end
  end
end
