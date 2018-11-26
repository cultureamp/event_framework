FooTestEvent = Class.new(EventFramework::DomainEvent)
FooTestErrorEvent = Class.new(EventFramework::DomainEvent)

module EventFramework
  RSpec.describe EventProcessor do
    let(:event_processor_subclass) do
      Class.new(EventProcessor) do
        attr_reader :foo_test_event

        process FooTestEvent do |aggregate_id, domain_event, metadata|
          @foo_test_event = [aggregate_id, domain_event, metadata]
        end

        process FooTestErrorEvent do
          raise 'the roof'
        end
      end
    end
    let(:error_reporter) { double(:error_reporter) }
    subject(:event_processor) { event_processor_subclass.new(error_reporter: error_reporter) }

    describe '#handled_event_classes' do
      it 'returns the handled event classes' do
        expect(event_processor.handled_event_classes).to eq [FooTestEvent, FooTestErrorEvent]
      end
    end

    describe '#handle_event' do
      let(:metadata) { double :metadata }
      let(:event_id) { double :event_id }
      let(:aggregate_id) { double :aggregate_id }
      let(:domain_event) { FooTestEvent.new }
      let(:event) do
        instance_double(
          Event,
          id: event_id,
          domain_event: domain_event,
          aggregate_id: aggregate_id,
          metadata: metadata,
        )
      end

      it 'handles the event' do
        event_processor.handle_event(event)

        expect(event_processor.foo_test_event).to eq [aggregate_id, domain_event, metadata]
      end

      context 'when an error occurs' do
        let(:domain_event) { FooTestErrorEvent.new }
        subject(:event_processor) { event_processor_subclass.new(error_reporter: error_reporter) }

        it 'calls the "error reporter" callback and re-raises' do
          error = an_object_having_attributes(class: RuntimeError, message: 'the roof')
          expect(error_reporter).to receive(:call).with(error, event)

          expect { event_processor.handle_event(event) }.to raise_error error
        end
      end
    end
  end
end
