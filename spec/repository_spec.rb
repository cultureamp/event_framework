require 'dry/struct'

module EventFramework
  RSpec.describe Repository do
    let(:sink) { double(EventStore::Sink) }
    let(:source) { double(EventStore::Source) }
    let(:repository) { Repository.new(sink: sink, source: source) }

    describe '#new_aggregate' do
      let(:aggregate_id) { SecureRandom.uuid }
      let(:aggregate_class) { class_double(Aggregate) }
      let(:aggregate) { instance_double(Aggregate) }

      it 'returns a new aggregate with loaded events', aggregate_failures: true do
        expect(source).to receive(:get_for_aggregate)
          .with(aggregate_id)
          .and_return([])
        expect(aggregate_class).to receive(:build).with(aggregate_id).and_return(aggregate)
        expect(repository.new_aggregate(aggregate_class, aggregate_id)).to eq aggregate
      end

      context 'with existing events' do
        it 'raises an error' do
          expect(source).to receive(:get_for_aggregate)
            .with(aggregate_id)
            .and_return([:event_1])

          expect { repository.new_aggregate(aggregate_class, aggregate_id) }
            .to raise_error Repository::AggregateAlreadyExists, aggregate_id
        end
      end
    end

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

      context 'with no events' do
        it 'raises an error' do
          expect(source).to receive(:get_for_aggregate)
            .with(aggregate_id)
            .and_return([])

          expect { repository.load_aggregate(aggregate_class, aggregate_id) }
            .to raise_error Repository::AggregateNotFound, aggregate_id
        end
      end
    end

    describe '#save_aggregate' do
      let(:event_1) { fake_event_class.new(aggregate_sequence: 5) }
      let(:event_2) { fake_event_class.new(aggregate_sequence: 6) }
      let(:aggregate) { instance_double(Aggregate, staged_events: [event_1, event_2]) }
      let(:metadata) { { account_id: SecureRandom.uuid } }
      let(:fake_event_class) do
        Class.new(DomainStruct) do
          attribute :aggregate_sequence, Types::Strict::Integer
          attribute :mutable_metadata, Types::Hash.meta(omittable: true)
        end
      end

      it 'sinks the aggregates staged events with metadata' do
        expect(sink).to receive(:sink).with [
          event_1.new(mutable_metadata: metadata),
          event_2.new(mutable_metadata: metadata),
        ]

        repository.save_aggregate(aggregate, metadata: metadata)
      end

      context 'with ensure_new_aggregate: true' do
        it 'sinks the aggregates staged events setting with the aggregate_sequence starting at 1' do
          expect(sink).to receive(:sink).with [
            event_1.new(aggregate_sequence: 1, mutable_metadata: metadata),
            event_2.new(aggregate_sequence: 2, mutable_metadata: metadata),
          ]

          repository.save_aggregate(aggregate, metadata: metadata, ensure_new_aggregate: true)
        end
      end
    end
  end
end
