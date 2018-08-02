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
        @command_class = klass
        @callable = block
      end
    end

    def initialize(metadata:, repository: Repository.new)
      @repository = repository
      @metadata = metadata
    end

    def handle(aggregate_id, command)
      raise NotImplementedError if command_class.nil? || callable.nil?
      raise MismatchedCommandError, "Received command of type #{command.class}; expected #{command_class}" unless command.is_a?(command_class)

      begin
        execution_attempts ||= FAILURE_RETRY_THRESHOLD
        instance_exec(aggregate_id, command, &callable)
      rescue RetriableException
        (execution_attempts -= 1).zero? ? raise(RetryFailureThresholdExceededException) : retry
      end
    end

    private

    def_delegators 'self.class', :command_class, :callable

    attr_reader :metadata

    def with_aggregate(aggregate_class, aggregate_id)
      aggregate = repository.load_aggregate(aggregate_class, aggregate_id)

      yield aggregate

      repository.save_aggregate(aggregate, metadata: metadata)
    end

    def with_new_aggregate(aggregate_class, aggregate_id)
      aggregate = repository.load_aggregate(aggregate_class, aggregate_id)

      yield aggregate

      repository.save_aggregate(aggregate, metadata: metadata, ensure_new_aggregate: true)
    end
  end
end
