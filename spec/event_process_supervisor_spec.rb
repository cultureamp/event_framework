module EventFramework
  RSpec.describe EventProcessorSupervisor do
    describe '.call' do
      let(:event_processor_class) { class_double(EventProcessor, name: 'FooProjector') }
      let(:process_manager) { instance_double(Forked::ProcessManager) }

      it 'forks each event processor using supervisor' do
        expect(EventFramework::EventProcessorWorker).to receive(:call)
          .with(event_processor_class: event_processor_class)
        expect(process_manager).to receive(:fork).with('FooProjector').and_yield
        expect(process_manager).to receive(:wait_for_shutdown)

        described_class.call(
          processor_classes: [event_processor_class],
          process_manager: process_manager,
        )
      end
    end
  end
end
