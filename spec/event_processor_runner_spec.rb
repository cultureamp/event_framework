module EventFramework
  RSpec.describe EventProcessorRunner do
    describe ".call" do
      let(:event_processor_class) { class_double(EventProcessor, name: "FooProjector") }
      let(:event_processor) { instance_double(event_processor_class) }

      let(:logger) { instance_double(Logger) }

      let(:bookmark) { instance_double(Bookmark) }

      let(:event_source) { instance_double(EventFramework::EventStore::Source) }

      let(:bookmark_repository) { instance_double(BookmarkRepository) }

      before do
        allow(event_processor_class).to receive(:new).and_return(event_processor)
        allow(Logger).to receive(:new).with($stdout).at_least(1).and_return(logger)

        projection_database = instance_spy(EventFramework::DatabaseConnection)
        allow(TestDomain).to receive(:database).with(:projections).and_return(projection_database)
        allow(BookmarkRepository).to receive(:new)
          .with(name: "FooProjector", database: projection_database).and_return(bookmark_repository)

        container = double(:container)
        allow(TestDomain).to receive(:container).and_return(container)
        allow(container).to receive(:resolve).with("event_store.source")
          .and_return(event_source)
      end

      it "runs an event processor" do
        allow(bookmark_repository).to receive(:checkout).and_return(bookmark)
        tracer = EventFramework::Tracer::NullTracer.new
        expect(EventFramework::EventProcessorWorker).to receive(:call).with(
          event_processor: event_processor,
          bookmark: bookmark,
          logger: logger,
          tracer: tracer,
          event_source: event_source
        )

        EventProcessorRunner.new(
          processor_class: event_processor_class,
          domain_context: TestDomain,
          tracer: tracer,
          logger: logger
        ).call
      end

      context "when unable to checkout a bookmark" do
        it "logs the error" do
          expect(bookmark_repository).to receive(:checkout).and_raise(BookmarkRepository::UnableToCheckoutBookmarkError)
          allow(bookmark_repository).to receive(:checkout).and_return(bookmark)
          allow(EventFramework::EventProcessorWorker).to receive(:call)

          expect(logger).to receive(:info).with(
            processor_class_name: "FooProjector",
            msg: "EventFramework::BookmarkRepository::UnableToCheckoutBookmarkError"
          )

          EventProcessorRunner.new(
            processor_class: event_processor_class,
            domain_context: TestDomain
          ).call
        end
      end
    end
  end
end
