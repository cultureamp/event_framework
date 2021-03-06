require "dry/struct"

module EventFramework
  RSpec.describe Repository do
    let(:sink) { instance_double(EventStore::Sink) }
    let(:source) { instance_double(EventStore::Source) }
    let(:repository) { Repository.new(sink: sink, source: source) }

    describe "#new_aggregate" do
      let(:aggregate_id) { SecureRandom.uuid }
      let(:aggregate_class) { class_double(Aggregate) }
      let(:aggregate) { instance_double(Aggregate) }

      it "returns a new, empty aggregate", aggregate_failures: true do
        expect(source).to receive(:get_for_aggregate)
          .with(aggregate_id)
          .and_return([])
        expect(aggregate_class).to receive(:build).with(aggregate_id).and_return(aggregate)
        expect(repository.new_aggregate(aggregate_class, aggregate_id)).to eq aggregate
      end

      context "with existing events" do
        it "raises an error" do
          expect(source).to receive(:get_for_aggregate)
            .with(aggregate_id)
            .and_return([:event_1])

          expect { repository.new_aggregate(aggregate_class, aggregate_id) }
            .to raise_error Repository::AggregateAlreadyExists, aggregate_id
        end
      end
    end

    describe "#load_aggregate" do
      let(:aggregate_id) { SecureRandom.uuid }
      let(:aggregate_class) { class_double(Aggregate) }
      let(:aggregate) { instance_double(Aggregate) }

      it "returns a new aggregate with loaded events", aggregate_failures: true do
        expect(source).to receive(:get_for_aggregate)
          .with(aggregate_id)
          .and_return([:event_1, :event_2])
        expect(aggregate_class).to receive(:build).with(aggregate_id).and_return(aggregate)
        expect(aggregate).to receive(:load_events).with([:event_1, :event_2])
        expect(repository.load_aggregate(aggregate_class, aggregate_id)).to eq aggregate
      end

      context "with no events" do
        it "raises an error" do
          expect(source).to receive(:get_for_aggregate)
            .with(aggregate_id)
            .and_return([])

          expect { repository.load_aggregate(aggregate_class, aggregate_id) }
            .to raise_error Repository::AggregateNotFound, aggregate_id
        end
      end
    end

    describe "#new_or_existing_aggregate" do
      let(:aggregate_id) { SecureRandom.uuid }
      let(:aggregate_class) { class_double(Aggregate) }
      let(:aggregate) { instance_double(Aggregate) }

      context "with events" do
        before do
          expect(source).to receive(:get_for_aggregate)
            .with(aggregate_id)
            .and_return([:event_1, :event_2])
        end

        it "returns an existing aggregate with loaded events", aggregate_failures: true do
          expect(aggregate_class).to receive(:build).with(aggregate_id).and_return(aggregate)
          expect(aggregate).to receive(:load_events).with([:event_1, :event_2])
          expect(repository.new_or_existing_aggregate(aggregate_class, aggregate_id)).to eq aggregate
        end
      end

      context "with no events" do
        before do
          expect(source).to receive(:get_for_aggregate)
            .with(aggregate_id)
            .and_return([])
        end

        it "returns a new, empty aggregate" do
          expect(aggregate_class).to receive(:build).with(aggregate_id).and_return(aggregate)
          expect(aggregate).to receive(:load_events).with([])
          expect(repository.new_or_existing_aggregate(aggregate_class, aggregate_id)).to eq aggregate
        end
      end
    end

    describe "#save_aggregate" do
      let(:event_1) { fake_event_class.new(aggregate_sequence: 5) }
      let(:event_2) { fake_event_class.new(aggregate_sequence: 6) }
      let(:aggregate) { instance_double(Aggregate, staged_events: [event_1, event_2]) }
      let(:metadata) { {account_id: SecureRandom.uuid} }
      let(:fake_event_class) do
        Class.new(DomainStruct) do
          attribute :aggregate_sequence, Types::Strict::Integer
          attribute :metadata, Types::Hash.meta(omittable: true)
        end
      end

      it "sinks the aggregates staged events with metadata" do
        expect(sink).to receive(:sink).with [
          event_1.new(metadata: metadata),
          event_2.new(metadata: metadata)
        ]

        repository.save_aggregate(aggregate, metadata: metadata)
      end

      context "with ensure_new_aggregate: true" do
        it "sinks the aggregates staged events setting with the aggregate_sequence starting at 1" do
          expect(sink).to receive(:sink).with [
            event_1.new(aggregate_sequence: 1, metadata: metadata),
            event_2.new(aggregate_sequence: 2, metadata: metadata)
          ]

          repository.save_aggregate(aggregate, metadata: metadata, ensure_new_aggregate: true)
        end
      end
    end
  end
end
