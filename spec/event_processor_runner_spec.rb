module EventFramework
  RSpec.describe EventProcessorRunner do
    describe ".call" do
      let(:event_processor_class) { class_double(EventProcessor, name: "FooProjector") }
      let(:event_processor) { instance_double(event_processor_class) }

      let(:logger) { instance_double(Logger) }

      let(:bookmark) { instance_double(Bookmark) }

      let(:event_source) { instance_double(EventFramework::EventStore::Source) }

      before do
        allow(event_processor_class).to receive(:new).and_return(event_processor)

        allow(Logger).to receive(:new).with(STDOUT).at_least(1).and_return(logger)

        projection_database = instance_spy(EventFramework::DatabaseConnection)
        allow(TestDomain).to receive(:database).with(:projections).and_return(projection_database)
        bookmark_repository = instance_double(BookmarkRepository)
        allow(BookmarkRepository).to receive(:new)
          .with(name: "FooProjector", database: projection_database).and_return(bookmark_repository)
        allow(bookmark_repository).to receive(:checkout).and_return(bookmark)

        container = double(:container)
        allow(TestDomain).to receive(:container).and_return(container)
        allow(container).to receive(:resolve).with("event_store.source")
          .and_return(event_source)
      end

      it "runs an event processor" do
        expect(EventFramework::EventProcessorWorker).to receive(:call).with(
          event_processor: event_processor,
          bookmark: bookmark,
          logger: logger,
          event_source: event_source
        )

        EventProcessorRunner.new(
          processor_class: event_processor_class,
          domain_context: TestDomain
        ).call
      end
    end
  end
end
