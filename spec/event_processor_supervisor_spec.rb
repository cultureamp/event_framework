module EventFramework
  RSpec.describe EventProcessorSupervisor do
    describe '.call' do
      let(:event_processor_class) { class_double(EventProcessor, name: 'FooProjector') }
      let(:process_manager) { instance_double(Forked::ProcessManager) }
      let(:bookmark_repository_class) { class_double(BookmarkRepository) }
      let(:bookmark_repository) { instance_double(BookmarkRepository) }
      let(:bookmark) { instance_double(Bookmark) }
      let(:event_processor) { instance_double(event_processor_class) }
      let(:logger) { instance_double(Logger) }
      let(:event_processor_error_reporter) { double(:event_processor_error_reporter) }
      let(:on_forked_error) { instance_double(described_class::OnForkedError) }

      it 'forks each event processor' do
        expect(described_class::OnForkedError).to receive(:new).with('FooProjector').and_return(on_forked_error)
        expect(process_manager).to receive(:fork).with('FooProjector', on_error: on_forked_error).and_yield
        expect(Logger).to receive(:new).with(STDOUT).and_return(logger)
        expect(event_processor_class).to receive(:new).and_return(event_processor)
        expect(bookmark_repository_class).to receive(:new)
          .with(name: 'FooProjector').and_return(bookmark_repository)
        expect(bookmark_repository).to receive(:checkout)
          .and_return(bookmark)
        expect(process_manager).to receive(:wait_for_shutdown)
        expect(EventFramework::EventProcessorWorker).to receive(:call).with(
          event_processor: event_processor,
          bookmark: bookmark,
          logger: logger,
        )

        described_class.call(
          processor_classes: [event_processor_class],
          process_manager: process_manager,
          bookmark_repository_class: bookmark_repository_class,
        )
      end
    end
  end
end
