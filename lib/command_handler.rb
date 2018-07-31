module EventFramework
  class CommandHandler
    MismatchedCommand = Class.new(Error)

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
      raise NotImplementedError if self.class.command_class.nil? || self.class.callable.nil?
      unless command.is_a?(self.class.command_class)
        raise MismatchedCommand, "Received command of type #{command.class}; expected #{self.class.command_class}"
      end
      instance_exec(aggregate_id, command, &self.class.callable)
    end

    private

    attr_reader :metadata

    def with_aggregate(aggregate_class, aggregate_id)
      aggregate = repository.load_aggregate(aggregate_class, aggregate_id)

      yield aggregate

      repository.save_aggregate(aggregate)
    end

    # TODO: with_new_aggregate
  end
end
