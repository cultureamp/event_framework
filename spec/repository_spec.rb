require 'dry/struct'

module EventFramework
  RSpec.describe Repository do
    let(:sink) { double(EventStore::Sink) }
    let(:source) { double(EventStore::Source) }
    let(:repository) { Repository.new(sink: sink, source: source) }

    describe '#load_aggregate' do
      let(:aggregate_id) { SecureRandom.uuid }
      let(:aggregate_class) { class_double(Aggregate) }
      let(:aggregate) { instance_double(Aggregate) }

      it 'returns a new aggregate with loaded events', aggregate_failures: true do
        expect(source).to receive(:get_for_aggregate)
          .with(aggregate_id)
          .and_return([:event_1, :event_2])
        expect(aggregate_class).to receive(:build).with(aggregate_id).and_return(aggregate)
        expect(aggregate).to receive(:load_events).with([:event_1, :event_2])
        expect(repository.load_aggregate(aggregate_class, aggregate_id)).to eq aggregate
      end
    end

    describe '#save_aggregate' do
      let(:event_1) { fake_event_class.new(aggregate_sequence: 5) }
      let(:event_2) { fake_event_class.new(aggregate_sequence: 6) }
      let(:aggregate) { instance_double(Aggregate, staged_events: [event_1, event_2]) }
      let(:metadata) { { account_id: SecureRandom.uuid } }
      let(:fake_event_class) do
        Class.new(Dry::Struct) do
          attribute :aggregate_sequence, Types::Strict::Integer
          attribute :metadata, Types::Hash.meta(omittable: true)
        end
      end

      it 'sinks the aggregates staged events with metadata' do
        expect(sink).to receive(:sink).with [
          event_1.new(metadata: metadata),
          event_2.new(metadata: metadata),
        ]

        repository.save_aggregate(aggregate, metadata)
      end
    end
  end
end
