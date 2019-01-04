require 'forwardable'

module EventFramework
  # Public: Encapsulates the process of executing a command against an aggregate
  # within an event-sourced system.
  class CommandHandler
    extend Forwardable

    FAILURE_RETRY_THRESHOLD = 5
    FAILURE_RETRY_SLEEP_INTERVAL = 0.5

    MismatchedCommandError = Class.new(Error)
    RetryFailureThresholdExceededException = Class.new(Error)

    # Public: Returns the instance of Repository used by `with_aggregate`
    # and `with_new_aggregate`
    attr_reader :repository

    class << self
      # Public: Returns the Proc that is executed on invocation of
      # the CommandHandler
      attr_reader :handler_proc

      # Public: Returns the Class that defines the structure of the data
      # required by the CommandHandler
      attr_reader :command_class

      # Public: Returns a new sub-class of CommandHandler with an overloaded
      # constructor that automatically injects required dependencies from
      # the given context_module
      #
      # This is a handy bit of syntactic magic which allows
      #
      # context_module - A Module that has been prepared as a context using
      #                  BoundedContext.initialize_bounded_context and
      #                  BoundedContext.build_command_dependency_chain!
      def [](context_module)
        Class.new(self).tap do |subclass|
          context_repository = context_module.container.resolve('repository')

          subclass.define_singleton_method(:new) do |repository: context_repository|
            allocate.tap do |instance|
              instance.send(:initialize, repository: repository)
            end
          end
        end
      end

      # Public: Define the behaviour to be executed on invocation of
      # this CommandHandler.
      #
      # Each CommandHandler requires two components:
      #
      #  * a data object representing the input to the command
      #  * a block that encapsulates command-specific behaviour
      #
      # Separating these concerns allows the `handle` method to focus on
      # implementing the boiler-plate logic of argument validation, aggregate
      # hydration, and retry-on-failure
      #
      # command_class - The Class<Command> that defines the data structure
      #                 expected by the given block
      # handler_proc  - The block to be executed on invocation
      #
      # Returns nothing.
      def handle(command_class, &handler_proc)
        raise ArgumentError unless command_class.is_a?(Class)

        @command_class = command_class
        @handler_proc = handler_proc
      end
    end

    # Public: Initializes a CommandHandler
    #
    # repository - A Repository, pre-configured with the required Event Sink and
    # Event Store
    def initialize(repository:)
      @repository = repository
    end

    # Public: Invoke the CommandHandler
    #
    # command  - A Command, containing the data to be used during invocation.
    #            Must be an instance of the class defined on the singleton class
    #            via `CommandHander::handle`
    # executor - An instance of Executor, representing the user invoking this
    #            command.
    # metadata - The Metadata pertaining to this specific command invocation.
    #
    # Returns nothing.
    #
    # Raises MismatchedCommandError if `command` is not an instance of the
    # expected command class.
    # Raises NotImplementedError if no handler has been defined.
    # Raises RetryFailureThresholdExceededException if the number of automatic
    # retries exceeds the designated threshold.
    def call(command:, executor:, metadata:)
      raise NotImplementedError if command_class.nil? || handler_proc.nil?
      raise MismatchedCommandError, "Received command of type #{command.class}; expected #{command_class}" unless command.is_a?(command_class)

      # ensure that the instance of metadata passed in as an argument to `call`
      # is available via the attribute accessor when calling with_aggregate, et al
      self.metadata = metadata

      begin
        execution_attempts ||= FAILURE_RETRY_THRESHOLD
        instance_exec(command, executor, metadata, &handler_proc)
      rescue RetriableException
        if (execution_attempts -= 1).zero?
          raise RetryFailureThresholdExceededException
        else
          sleep FAILURE_RETRY_SLEEP_INTERVAL
          retry
        end
      end
    end

    private

    # Make `command_class` and `handler_proc` accessible as instance-level accessors
    def_delegators 'self.class', :command_class, :handler_proc

    private :command_class, :handler_proc

    # Internal: the Metadata passed to `handle`
    attr_accessor :metadata

    # Internal: Hydrates an instance of the given aggregate class by fetching
    # a sequence of events from the Event Source, via a Repository.
    #
    # It then yields to the the handler, and persists any newly-generate events
    # into the Event Sink (again, via the Repository)
    #
    # aggregate_class - the Class<Aggregate> to hydrate
    # aggregate_id    - a String containing the UUID of the instance of
    #                   aggregate_class to hydrate
    #
    # Yields an instance of the Class passed in via AggregateClass
    #
    # Raises Repository::AggregateNotFound if no events for the given
    # aggregate_id exist in the Event Source
    def with_aggregate(aggregate_class, aggregate_id)
      aggregate = repository.load_aggregate(aggregate_class, aggregate_id)

      yield aggregate

      repository.save_aggregate(aggregate, metadata: metadata)
    end

    # Internal: Initializes an empty instance of the given aggregate class,
    # ensuring no events currently exist for the given id, via a Repository
    #
    # It then yields to the the handler, and persists any newly-generate events
    # into the Event Sink (again, via the Repository)
    #
    # aggregate_class - the Class<Aggregate> to hydrate
    # aggregate_id    - a String containing the UUID of the instance of
    #                   aggregate_class to hydrate
    #
    # Yields an instance of the Class passed in via AggregateClass
    #
    # Raises Repository::AggregateAlreadyExists if events for the given
    # aggregate_id exist in the Event Source
    def with_new_aggregate(aggregate_class, aggregate_id)
      aggregate = repository.new_aggregate(aggregate_class, aggregate_id)

      yield aggregate

      repository.save_aggregate(aggregate, metadata: metadata, ensure_new_aggregate: true)
    end
  end
end
