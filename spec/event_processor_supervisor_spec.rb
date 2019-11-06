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
      let(:event_source) { instance_double(EventFramework::EventStore::Source) }
      let(:projection_database) { instance_spy(EventFramework::DatabaseConnection) }
      let(:ready_to_stop) { -> {} }
      let(:ready_to_stop_wrapper) { double(to_proc: ready_to_stop) }

      it 'forks each event processor' do
        expect(described_class::OnForkedError).to receive(:new).with('FooProjector').and_return(on_forked_error)
        expect(process_manager).to receive(:fork).with('FooProjector', on_error: on_forked_error).and_yield(ready_to_stop_wrapper)
        expect(Logger).to receive(:new).with(STDOUT).at_least(1).and_return(logger)
        expect(event_processor_class).to receive(:new).and_return(event_processor)
        expect(bookmark_repository_class).to receive(:new)
          .with(name: 'FooProjector', database: projection_database).and_return(bookmark_repository)
        expect(bookmark_repository).to receive(:checkout)
          .and_return(bookmark)
        expect(process_manager).to receive(:wait_for_shutdown)
        expect(EventFramework::EventProcessorWorker).to receive(:call).with(
          event_processor: event_processor,
          bookmark: bookmark,
          logger: logger,
          event_source: event_source,
        ) do |&block|
          expect(block).to eq ready_to_stop
        end

        described_class.new(
          processor_classes: [event_processor_class],
          process_manager: process_manager,
          bookmark_repository_class: bookmark_repository_class,
          projection_database: projection_database,
          event_source: event_source,
        ).call
      end
    end
  end
end
