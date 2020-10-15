require "fork_break"

module TestDomain
  module Thing
    EventHappened = Class.new(EventFramework::DomainEvent) {
      attribute :foo, EventFramework::Types::String
    }
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
        .with("Thing", "EventHappened")
        .and_return(TestDomain::Thing::EventHappened)
    end

    def build_staged_event(aggregate_sequence: 1, aggregate_id: SecureRandom.uuid)
      StagedEvent.new(
        domain_event: TestDomain::Thing::EventHappened.new(foo: "bar"),
        aggregate_id: aggregate_id,
        aggregate_sequence: aggregate_sequence,
        aggregate_type: "Thing",
        event_type: "EventHappened",
        metadata: metadata
      )
    end

    let(:metadata) do
      Event::Metadata.new(
        account_id: SecureRandom.uuid,
        user_id: SecureRandom.uuid,
        correlation_id: SecureRandom.uuid
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

    context "persisting a single event to the database" do
      let(:aggregate_id) { SecureRandom.uuid }
      let(:staged_events) { [build_staged_event(aggregate_id: aggregate_id)] }

      let(:persisted_tuple) do
        persisted_tuples_for_aggregate(staged_events.first.aggregate_id).first
      end

      before do
        subject.sink(staged_events)
      end

      it "persists the main event attributes", aggregate_failures: true do
        expect(persisted_tuple).to include(
          id: a_string_matching(Types::UUID_REGEX),
          sequence: last_value_for_sequence("events_sequence_seq"),
          aggregate_sequence: 1,
          aggregate_id: aggregate_id,
          aggregate_type: "Thing",
          event_type: "EventHappened"
        )
      end

      it "persists the body as a JSON object" do
        body_hash = persisted_tuple[:body].to_h

        expect(body_hash).to include("foo" => "bar")
      end

      it "persists the metadata as a JSON object" do
        metadata_hash = persisted_tuple[:metadata].to_h

        expect(metadata_hash).to include(
          "account_id" => metadata.account_id,
          "user_id" => metadata.user_id,
          "correlation_id" => metadata.correlation_id
        )
      end

      it "generates a timestamp" do
        # Actually, 'it' doesn't. the database does, but we're testing it here anyway.
        expect(persisted_tuple[:created_at]).to be_within(2).of Time.now.utc
      end
    end

    context "when persisting multiple events" do
      let(:aggregate_id) { SecureRandom.uuid }
      let(:staged_events) do
        [
          build_staged_event(aggregate_id: aggregate_id, aggregate_sequence: 1),
          build_staged_event(aggregate_id: aggregate_id, aggregate_sequence: 2),
          build_staged_event(aggregate_id: aggregate_id, aggregate_sequence: 3)
        ]
      end

      let(:persisted_tuples) do
        persisted_tuples_for_aggregate(staged_events.first.aggregate_id)
      end

      it "persists multiple events in one call" do
        subject.sink(staged_events)

        expect(persisted_tuples.length).to eql 3
        expect(persisted_tuples.map { |t| t[:aggregate_sequence] }).to contain_exactly(1, 2, 3)
      end

      it "calls the after_sink_hook with the newly persisted events from the database" do
        aggregate_id = staged_events.first.aggregate_id

        expect(EventFramework.config.after_sink_hook).to receive(:call) do |events|
          expect(events).to match [
            an_object_having_attributes(
              aggregate_id: aggregate_id,
              aggregate_sequence: 1,
              domain_event: an_instance_of(TestDomain::Thing::EventHappened),
              metadata: an_object_having_attributes(**metadata.to_h)
            ),
            an_object_having_attributes(
              aggregate_id: aggregate_id,
              aggregate_sequence: 2,
              domain_event: an_instance_of(TestDomain::Thing::EventHappened),
              metadata: an_object_having_attributes(**metadata.to_h)
            ),
            an_object_having_attributes(
              aggregate_id: aggregate_id,
              aggregate_sequence: 3,
              domain_event: an_instance_of(TestDomain::Thing::EventHappened),
              metadata: an_object_having_attributes(**metadata.to_h)
            )
          ]
        end

        subject.sink(staged_events)
      end
    end

    describe "optimistic locking" do
      context "when the supplied aggregate_sequence has already been used" do
        let(:staged_events) { [build_staged_event(aggregate_sequence: 1)] }

        before do
          subject.sink(staged_events)
        end

        it "raises a concurrency error" do
          expect { subject.sink(staged_events) }.to raise_error described_class::ConcurrencyError
        end

        it "does not persist the event" do
          begin
            subject.sink(staged_events)
          rescue described_class::ConcurrencyError
          end

          expect(persisted_tuples_for_aggregate(staged_events.first.aggregate_id).length).to eql 1
        end
      end
    end

    describe "locking" do
      # A second database connection. The locking we're using,
      # pg_advisory_xact_lock, can be shared across the same connection.
      # Therefore we need to use a separate database connection to test that a
      # second connection cannot get the lock.
      let(:other_database_connection) do
        Sequel.connect(database.connection_url).tap do |db|
          db.extension :pg_json
        end
      end

      let(:d1) { database }
      let(:d2) { other_database_connection }
      let(:logger_1) { instance_spy(Logger) }
      let(:logger_2) { instance_spy(Logger) }
      let(:aggregate_id_1) { "00000000-0000-4000-a000-000000000001" }
      let(:aggregate_id_2) { "00000000-0000-4000-a000-000000000002" }
      let(:d1_transaction_sleep) { 0.4 }
      let(:lock_timeout_milliseconds) { nil }
      let(:t1) {
        fork {
          d1 = Sequel.connect(database.connection_url).tap do |db|
            db.extension :pg_json
          end

          Thread.current.report_on_exception = false # Don't double report RSpec failures

          # breakpoints << :after_thread_1_started

          sink_args = {
            database: d1,
            event_type_resolver: event_type_resolver,
            logger: logger_1,
            lock_timeout_milliseconds: lock_timeout_milliseconds
          }
          # Compact here so we use defaults of the supplied argument is nil.
          sink = described_class.new(sink_args.compact)

          print_flush "thread 1 sink"
          d1.transaction do
            sink.sink([build_staged_event(aggregate_id: aggregate_id_1)])

            # Sleep inside the transaction so we hold onto the lock longer.
            print_flush "thread 1 sleep"
            # breakpoints << :before_thread_1_transaction_finished
            sleep_spin_ms 100
            print_flush "thread 1 sleep finish"
          end
          print_flush "thread 1 sink finish"

          # Aggregate 2 should not be saved yet because it doesn't have a lock
          expect(database[:events].select_map(:aggregate_id)).not_to include(aggregate_id_2)

          # thread_1 finished = true
          d1.disconnect
          Sequel.synchronize { ::Sequel::DATABASES.delete(d1) }
        }
      }
      let(:t2) {
        fork {
          d2 = Sequel.connect(database.connection_url).tap do |db|
            db.extension :pg_json
          end

          Thread.current.report_on_exception = false # Don't double report RSpec failures

          # Sleep to ensure this thread gets the lock last, but less than the
          # sleep inside the transaction so that we try to get the lock while
          # the other lock is held.
          print_flush "thread 2 sleep"
          sleep_spin_ms 20
          print_flush "thread 2 sleep finish"

          sink_args = {
            database: d2,
            event_type_resolver: event_type_resolver,
            logger: logger_2,
            lock_timeout_milliseconds: lock_timeout_milliseconds
          }
          # Compact here so we use defaults of the supplied argument is nil.
          sink = described_class.new(sink_args.compact)

          print_flush "thread 2 sink"
          sink.sink([build_staged_event(aggregate_id: aggregate_id_2)])
          print_flush "thread 2 sink finish"

          # breakpoints << :after_thread_2_finished_sink

          d2.disconnect
          Sequel.synchronize { ::Sequel::DATABASES.delete(d2) }
        }
      }

      def sleep_spin_ms(ms)
        (0..ms).each do
          sleep 0.01
        end
      end

      def print_flush(msg)
        p msg
        $stdout.flush
      end

      # Expectation is in the t1 thread.
      def run_threads_with_expectation
        # t1.run_until(:before_thread_1_transaction_finished).wait
        # t2.run_until(:after_thread_2_finished_sink)
        # sleep 1
        # t1.finish.wait
        # t2.finish.wait
        initial_dbs = ::Sequel::DATABASES

        t1
        t2
        Process.waitall

        ::Sequel::DATABASES.replace(initial_dbs)
        # t1.run_until(:before_thread_1_transaction_finished).wait
        # t2.finish
        # t1.finish.wait
        # t2.finish.wait

        # loop do
        #   # [t1, t2].each { |t| t.join(0.1) }.all? { |x| x }
        #   r1 = t1.join(0.1)
        #   r2 = t2.join(0.1)
        #
        #   print_flush 1 => r1
        #   print_flush 2 => r2
        #
        #   break if r1 && r2
        # end
      end

      it "ensures events are sunk sequentially by locking the database" do
        run_threads_with_expectation

        expect(database[:events].select_map(:aggregate_id)).to match [aggregate_id_1, aggregate_id_2]
      ensure
        # disconnect_other_database_connection
      end

      context "hitting the lock timeout" do
        let(:lock_timeout_milliseconds) {
          lock_timeout = d1_transaction_sleep + 0.1
          (lock_timeout * 10).round
        }

        it "raises an exception" do
          expect { run_threads_with_expectation }.to raise_error described_class::ConcurrencyError

          expect(database[:events].select_map(:aggregate_id)).to match [aggregate_id_1]

          expect(logger_1).to_not have_received(:info)
          expect(logger_2).to have_received(:info).with(msg: "event_framework.event_store.sink.lock_error", correlation_id: metadata.correlation_id)
        ensure
          disconnect_other_database_connection
        end
      end

      def disconnect_other_database_connection
        # NOTE: Clean up the separate database connection so DatabaseCleaner
        # doesn't try to clean it.
        other_database_connection.disconnect
        Sequel.synchronize { ::Sequel::DATABASES.delete(other_database_connection) }
      end
    end

    describe "when passed no events" do
      it "returns nil" do
        expect(subject.sink([])).to be_nil
      end

      it "does not call the database" do
        database = double(:database)
        sinker = described_class.new(database: database, event_type_resolver: event_type_resolver)

        expect(database).not_to receive(:[])

        sinker.sink([])
      end
    end

    context "with missing metadata attributes" do
      let(:metadata) { Event::Metadata.new }

      it "raises an error" do
        expect { subject.sink [build_staged_event] }
          .to raise_error Dry::Struct::Error, /account_id is missing in Hash input/
      end
    end
  end
end
