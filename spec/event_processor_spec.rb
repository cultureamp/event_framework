FooTestEvent = Class.new

module EventFramework
  RSpec.describe EventProcessor do
    describe '.handled_event_classes' do
      let(:event_processor_subclass) do
        Class.new(EventProcessor) do
          process FooTestEvent do
          end
        end
      end

      it 'returns the handled event classes' do
        expect(event_processor_subclass.handled_event_classes).to eq [FooTestEvent]
      end
    end
  end
end
