module EventFramework
  RSpec.describe EventProcessorSupervisor do
    describe '.call' do
      let(:logger) { instance_spy(Logger) }
      let(:on_forked_error) { instance_spy(described_class::OnForkedError) }

      let(:event_processor_class_name) { 'FooProjector' }
      let(:event_processor_class) { class_spy(EventProcessor, name: event_processor_class_name) }
      let(:event_processor) { instance_spy(event_processor_class) }

      let(:process_manager) { instance_spy(Forked::ProcessManager) }

      let(:bookmark_repository) { instance_spy(BookmarkRepository) }
      let(:bookmark) { instance_spy(Bookmark) }

      let(:event_processor_worker) { class_spy(EventProcessorWorker) }

      before do
        allow(described_class::OnForkedError).to receive(:new).with(event_processor_class_name).and_return(on_forked_error)
        allow(process_manager).to receive(:fork).and_yield
        allow(Logger).to receive(:new).with(STDOUT).and_return(logger)
        allow(bookmark_repository).to receive(:checkout).with(event_processor_class_name).and_return(bookmark)
        allow(event_processor_class).to receive(:new).and_return(event_processor)

        stub_const('EventFramework::EventProcessorWorker', event_processor_worker)
      end

      it 'forks each event processor' do
        described_class.call(
          processor_classes: [event_processor_class],
          process_manager: process_manager,
          bookmark_repository: bookmark_repository,
        )

        expect(process_manager).to have_received(:fork).with(event_processor_class_name, on_error: on_forked_error)

        expect(event_processor_worker).to have_received(:call).with(
          event_processor: event_processor,
          bookmark: bookmark,
          logger: logger,
        )

        expect(process_manager).to have_received(:wait_for_shutdown)
      end
    end
  end
end
