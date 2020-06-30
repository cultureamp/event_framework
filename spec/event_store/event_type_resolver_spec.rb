module TestDomain
  module Thing
    EventTypeSerializationTested = Class.new(EventFramework::DomainEvent)
    EventTypeDeserializationTested = Class.new(EventFramework::DomainEvent)
  end
end

module Thing
  OtherEventTypeDeserializationTested = Class.new(EventFramework::DomainEvent)
end

OtherEventTypeDeserializationTested = Class.new(EventFramework::DomainEvent)

module EventFramework
  module EventStore
    RSpec.describe EventTypeResolver do
      subject(:event_type_resolver) { described_class.new(event_context_module: TestDomain) }

      describe "#serialize" do
        it "returns an event type description" do
          expect(event_type_resolver.serialize(TestDomain::Thing::EventTypeSerializationTested))
            .to eq EventTypeResolver::EventTypeDescription.new("EventTypeSerializationTested", "Thing")
        end
      end

      describe "#deserialize" do
        context "with an aggregate_type and an event_type" do
          it "returns the corresponding domain event class" do
            expect(event_type_resolver.deserialize("Thing", "EventTypeDeserializationTested"))
              .to eq TestDomain::Thing::EventTypeDeserializationTested
          end
        end

        context "with a missing argument" do
          it "raises an error" do
            expect { event_type_resolver.deserialize(nil, "EventTypeDeserializationTested") }.to raise_error(ArgumentError)
          end
        end

        context "with an unknown aggregate type" do
          it "raises an error" do
            expect { event_type_resolver.deserialize("OtherThing", "EventTypeDeserializationTested") }
              .to raise_error described_class::UnknownEventTypeError, "OtherThing::EventTypeDeserializationTested"
          end
        end

        context "with an unknown event type" do
          it "raises an error" do
            expect { event_type_resolver.deserialize("Thing", "UnknownEvent") }
              .to raise_error described_class::UnknownEventTypeError, "Thing::UnknownEvent"
          end
        end

        context "when called with a class name that exists outside the declared parent domain" do
          it "raises an error" do
            expect { event_type_resolver.deserialize("Thing", "OtherEventTypeDeserializationTested") }
              .to raise_error described_class::UnknownEventTypeError, "Thing::OtherEventTypeDeserializationTested"
          end
        end
      end
    end
  end
end
