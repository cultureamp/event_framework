module EventFramework
  class CommandHandler
    extend Forwardable

    FAILURE_RETRY_THRESHOLD = 3

    MismatchedCommandError = Class.new(Error)
    RetryFailureThresholdExceededException = Class.new(Error)

    attr_reader :repository

    class << self
      attr_reader :command_class, :callable

      def handle(klass, &block)
        raise ArgumentError unless klass.is_a?(Class)

        @command_class = klass
        @callable = block
      end
    end

    def initialize(repository: Repository.new)
      @repository = repository
    end

    def handle(command:, executor:, metadata:)
      raise NotImplementedError if command_class.nil? || callable.nil?
      raise MismatchedCommandError, "Received command of type #{command.class}; expected #{command_class}" unless command.is_a?(command_class)

      # ensure that the instance of metadata passed in as an argument to `handle`
      # is available via the attribute accessor when calling with_aggregate, et al
      self.metadata = metadata

      begin
        execution_attempts ||= FAILURE_RETRY_THRESHOLD
        instance_exec(command, executor, metadata, &callable)
      rescue RetriableException
        (execution_attempts -= 1).zero? ? raise(RetryFailureThresholdExceededException) : retry
      end
    end

    private

    def_delegators 'self.class', :command_class, :callable

    attr_accessor :metadata

    def with_aggregate(aggregate_class, aggregate_id)
      aggregate = repository.load_aggregate(aggregate_class, aggregate_id)

      yield aggregate

      repository.save_aggregate(aggregate, metadata: metadata)
    end

    def with_new_aggregate(aggregate_class, aggregate_id)
      aggregate = repository.new_aggregate(aggregate_class, aggregate_id)

      yield aggregate

      repository.save_aggregate(aggregate, metadata: metadata, ensure_new_aggregate: true)
    end
  end
end
