module TestDomain
  module Thing
    EventHappened = Class.new(EventFramework::DomainEvent) do
      attribute :foo, EventFramework::Types::String
    end
  end
end

module EventFramework
  RSpec.describe EventStore::Sink do
    let(:database) { TestDomain.database(:event_store) }
    let(:event_type_resolver) { instance_spy EventStore::EventTypeResolver }

    before do
      allow(event_type_resolver).to receive(:serialize)
        .with(TestDomain::Thing::EventHappened)
        .and_return(double(event_type: "EventHappened", aggregate_type: "Thing"))

      allow(event_type_resolver).to receive(:deserialize)
        .with('Thing', 'EventHappened')
        .and_return(TestDomain::Thing::EventHappened)
    end

    def build_staged_event(aggregate_sequence: 1, aggregate_id: SecureRandom.uuid)
      StagedEvent.new(
        domain_event: TestDomain::Thing::EventHappened.new(foo: 'bar'),
        aggregate_id: aggregate_id,
        aggregate_sequence: aggregate_sequence,
        aggregate_type: 'Thing',
        event_type: 'EventHappened',
        metadata: metadata,
      )
    end

    let(:metadata) do
      Event::Metadata.new(
        account_id: SecureRandom.uuid,
        user_id: SecureRandom.uuid,
        correlation_id: SecureRandom.uuid,
      )
    end

    def last_value_for_sequence(sequence_name)
      database["SELECT last_value FROM #{sequence_name}"].to_a.last[:last_value]
    end

    def persisted_tuples_for_aggregate(aggregate_id)
      database
        .from(:events)
        .where(aggregate_id: aggregate_id)
        .order(:sequence)
        .all
    end

    subject { described_class.new(database: database, event_type_resolver: event_type_resolver) }

    context 'persisting a single event to the database' do
      let(:aggregate_id) { SecureRandom.uuid }
      let(:staged_events) { [build_staged_event(aggregate_id: aggregate_id)] }

      let(:persisted_tuple) do
        persisted_tuples_for_aggregate(staged_events.first.aggregate_id).first
      end

      before do
        subject.sink(staged_events)
      end

      it 'persists the main event attributes', aggregate_failures: true do
        expect(persisted_tuple).to include(
          id: a_string_matching(Types::UUID_REGEX),
          sequence: last_value_for_sequence('events_sequence_seq'),
          aggregate_sequence: 1,
          aggregate_id: aggregate_id,
          aggregate_type: 'Thing',
          event_type: 'EventHappened',
        )
      end

      it 'persists the body as a JSON object' do
        body_hash = persisted_tuple[:body].to_h

        expect(body_hash).to include('foo' => 'bar')
      end

      it 'persists the metadata as a JSON object' do
        metadata_hash = persisted_tuple[:metadata].to_h

        expect(metadata_hash).to include(
          'account_id' => metadata.account_id,
          'user_id' => metadata.user_id,
          'correlation_id' => metadata.correlation_id,
        )
      end

      it 'generates a timestamp' do
        # Actually, 'it' doesn't. the database does, but we're testing it here anyway.
        expect(persisted_tuple[:created_at]).to be_within(2).of Time.now.utc
      end
    end

    context 'when persisting multiple events' do
      let(:aggregate_id) { SecureRandom.uuid }
      let(:staged_events) do
        [
          build_staged_event(aggregate_id: aggregate_id, aggregate_sequence: 1),
          build_staged_event(aggregate_id: aggregate_id, aggregate_sequence: 2),
          build_staged_event(aggregate_id: aggregate_id, aggregate_sequence: 3),
        ]
      end

      let(:persisted_tuples) do
        persisted_tuples_for_aggregate(staged_events.first.aggregate_id)
      end

      it 'persists multiple events in one call' do
        subject.sink(staged_events)

        expect(persisted_tuples.length).to eql 3
        expect(persisted_tuples.map { |t| t[:aggregate_sequence] }).to contain_exactly(1, 2, 3)
      end

      it 'calls the after_sink_hook with the newly persisted events from the database' do
        aggregate_id = staged_events.first.aggregate_id

        expect(EventFramework.config.after_sink_hook).to receive(:call) do |events|
          expect(events).to match [
            an_object_having_attributes(
              aggregate_id: aggregate_id,
              aggregate_sequence: 1,
              domain_event: an_instance_of(TestDomain::Thing::EventHappened),
              metadata: an_object_having_attributes(**metadata.to_h),
            ),
            an_object_having_attributes(
              aggregate_id: aggregate_id,
              aggregate_sequence: 2,
              domain_event: an_instance_of(TestDomain::Thing::EventHappened),
              metadata: an_object_having_attributes(**metadata.to_h),
            ),
            an_object_having_attributes(
              aggregate_id: aggregate_id,
              aggregate_sequence: 3,
              domain_event: an_instance_of(TestDomain::Thing::EventHappened),
              metadata: an_object_having_attributes(**metadata.to_h),
            ),
          ]
        end

        subject.sink(staged_events)
      end
    end

    describe 'optimistic locking' do
      context 'when the supplied aggregate_sequence has already been used' do
        let(:staged_events) { [build_staged_event(aggregate_sequence: 1)] }

        before do
          subject.sink(staged_events)
        end

        it 'raises a concurrency error' do
          expect { subject.sink(staged_events) }.to raise_error described_class::ConcurrencyError
        end

        it 'does not persist the event' do
          begin
            subject.sink(staged_events)
          rescue described_class::ConcurrencyError # rubocop:disable Lint/SuppressedException
          end

          expect(persisted_tuples_for_aggregate(staged_events.first.aggregate_id).length).to eql 1
        end
      end
    end

    describe 'locking' do
      let(:database_wrapper) do
        # Testing concurrency can be painful, however there are some direct
        # metrics we can reasonably expect to occur, given our implementation.
        #
        # We know that we're relying on PostgreSQL's table-locking feature[1]
        # to ensure sequentiality when sinking events.
        #
        # Givent the way we've implemented locking, it's reasonable to assume
        # that given a series of connections (c1, c2... cn), the number of
        # times each connection has to call `pg_try_advisory_xact_lock` will be
        # greater than that of the connection that preceded it.
        #
        # We can measure this by injecting an object that delegates all
        # behaviour to the actual connection object, but also measures the data
        # we need to be able to assert our expectations.
        #
        # In addition, we can also use the same object to introduce an
        # artificial delay, in order to make measurement more reliable.
        #
        # [1]: https://www.postgresql.org/docs/10/explicit-locking.html
        Class.new(SimpleDelegator) do
          attr_reader :__try_lock_count

          def select(pg_function)
            @__try_lock_count ||= 0
            @__try_lock_count += 1 if pg_function.name == :pg_try_advisory_xact_lock

            __getobj__.select(pg_function)
          end

          def transaction
            __getobj__.transaction do
              yield
              sleep 0.2
            end
          end
        end
      end

      let(:other_database_connection) do
        Sequel.connect(database.connection_url).tap do |db|
          db.extension :pg_json
        end
      end

      let(:d1) { database_wrapper.new(database) }
      let(:d2) { database_wrapper.new(other_database_connection) }
      let(:logger_1) { instance_spy(Logger) }
      let(:logger_2) { instance_spy(Logger) }
      let(:aggregate_id_1) { '00000000-0000-4000-a000-000000000001' }
      let(:aggregate_id_2) { '00000000-0000-4000-a000-000000000002' }

      it 'ensures events are sunk sequentially by locking the database' do
        t1 = Thread.new do
          sinker = described_class.new(database: d1, event_type_resolver: event_type_resolver, logger: logger_1)
          Thread.current.report_on_exception = false # Don't double report RSpec failures
          sinker.sink([build_staged_event(aggregate_id: aggregate_id_1)])

          # Aggregate 2 should not be saved yet because it doesn't have a lock
          expect(database[:events].select_map(:aggregate_id)).not_to include(aggregate_id_2)
        end

        t2 = Thread.new do
          sinker = described_class.new(database: d2, event_type_resolver: event_type_resolver, logger: logger_2)
          sleep 0.1 # Ensure this thread gets the lock last
          sinker.sink([build_staged_event(aggregate_id: aggregate_id_2)])
        end

        [t1, t2].each(&:join)

        expect(d1.__try_lock_count).to be < d2.__try_lock_count

        expect(logger_1).to_not have_received(:info)
        expect(logger_2).to have_received(:info).with(
          msg: 'event_framework.event_store.sink.retry',
          tries: an_instance_of(Integer),
          correlation_id: metadata.correlation_id,
        ).at_least(:once)
      ensure
        # NOTE: Clean up the separate database connection so DatabaseCleaner
        # doesn't try to clean it.
        other_database_connection.disconnect
        Sequel.synchronize { ::Sequel::DATABASES.delete(other_database_connection) }
      end
    end

    describe 'when passed no events' do
      it 'returns nil' do
        expect(subject.sink([])).to be_nil
      end

      it 'does not call the database' do
        database = double(:database)
        sinker = described_class.new(database: database, event_type_resolver: event_type_resolver)

        expect(database).not_to receive(:[])

        sinker.sink([])
      end
    end

    context 'with missing metadata attributes' do
      let(:metadata) { Event::Metadata.new }

      it 'raises an error' do
        expect { subject.sink [build_staged_event] }
          .to raise_error Dry::Struct::Error, /account_id is missing in Hash input/
      end
    end
  end
end
