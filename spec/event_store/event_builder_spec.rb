module TestDomain
  module Thing
    class EventBuilderTested < EventFramework::DomainEvent
      attribute :test, EventFramework::Types::Strict::String
    end

    class EventBuilderUpcastingTested < EventFramework::DomainEvent
      attribute :test, EventFramework::Types::Strict::String
      attribute :downcased_test, EventFramework::Types::Strict::String
      attribute :tested_at, EventFramework::Types::JSON::DateTime

      upcast do |row|
        row[:body][:downcased_test] = row[:body][:test].downcase
        row[:body][:tested_at] = row[:created_at].iso8601
        row
      end
    end
  end
end

module EventFramework
  RSpec.describe EventStore::EventBuilder do
    subject(:event_builder) { described_class.new(event_type_resolver: event_type_resolver) }
    let(:event_type_resolver) { instance_double(EventStore::EventTypeResolver) }

    before do
      allow(event_type_resolver).to receive(:deserialize).with("Thing", "EventBuilderTested").and_return(TestDomain::Thing::EventBuilderTested)
      allow(event_type_resolver).to receive(:deserialize).with("Thing", "EventBuilderUpcastingTested").and_return(TestDomain::Thing::EventBuilderUpcastingTested)
    end

    describe "#call", aggregate_failures: true do
      let(:event_id) { SecureRandom.uuid }
      let(:aggregate_id) { SecureRandom.uuid }
      let(:account_id) { SecureRandom.uuid }
      let(:user_id) { SecureRandom.uuid }
      let(:created_at) { Time.now.utc }
      let(:row) do
        {
          id: event_id,
          sequence: 1,
          aggregate_type: "Thing",
          event_type: "EventBuilderTested",
          aggregate_id: aggregate_id,
          aggregate_sequence: 2,
          created_at: created_at,
          body: {
            test: "Testing!"
          },
          metadata: {
            "account_id" => account_id,
            "user_id" => user_id,
            "metadata_type" => "attributed"
          }
        }
      end

      let(:event) { event_builder.call(row) }

      it "returns an event" do
        expect(event).to be_a Event
        expect(event.id).to eq event_id
        expect(event.sequence).to eq 1
        expect(event.type).to eq TestDomain::Thing::EventBuilderTested
        expect(event.aggregate_id).to eq aggregate_id
        expect(event.aggregate_sequence).to eq 2
        expect(event.created_at).to eq created_at
      end

      it "has a domain event" do
        expect(event.domain_event).to be_a TestDomain::Thing::EventBuilderTested
        expect(event.domain_event.test).to eq "Testing!"
      end

      it "has a metadata object" do
        expect(event.metadata).to be_a Event::Metadata
        expect(event.metadata.account_id).to eq account_id
        expect(event.metadata.user_id).to eq user_id
        expect(event.metadata.metadata_type).to eq "attributed"
      end

      describe "metadata upcasting" do
        let(:event) do
          row[:metadata].delete("metadata_type")
          event_builder.call(row)
        end

        it 'defaults metadata_type to "attributed"' do
          expect(event.metadata.metadata_type).to eq "attributed"
        end
      end

      describe "unattributed metadata" do
        let(:event) do
          row[:metadata]["metadata_type"] = "unattributed"
          row[:metadata].delete("user_id")
          event_builder.call(row)
        end

        it "uses the UnattributedMetadata class" do
          expect(event.metadata).to be_an Event::UnattributedMetadata
          expect(event.metadata.metadata_type).to eq "unattributed"
        end
      end

      describe "system metadata" do
        let(:event) do
          row[:metadata]["metadata_type"] = "system"
          row[:metadata].delete("user_id")
          event_builder.call(row)
        end

        it "uses the SystemMetadata class" do
          expect(event.metadata).to be_an Event::SystemMetadata
          expect(event.metadata.metadata_type).to eq "system"
        end
      end

      describe "upcasting" do
        let(:event) { event_builder.call(row.merge(event_type: "EventBuilderUpcastingTested")) }

        it "upcasts the event" do
          expect(event.domain_event.test).to eq "Testing!"
          expect(event.domain_event.downcased_test).to eq "testing!"
          expect(event.domain_event.tested_at.year).to eq Date.today.year
        end
      end
    end
  end
end
