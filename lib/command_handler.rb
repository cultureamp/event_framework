module EventFramework
  class CommandHandler
    extend Forwardable

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
      raise NotImplementedError if command_class.nil? || callable.nil?
      raise MismatchedCommand, "Received command of type #{command.class}; expected #{command_class}" unless command.is_a?(command_class)

      instance_exec(aggregate_id, command, &callable)
    end

    private

    def_delegators 'self.class', :command_class, :callable

    attr_reader :metadata

    def with_aggregate(aggregate_class, aggregate_id)
      aggregate = repository.load_aggregate(aggregate_class, aggregate_id)

      yield aggregate

      repository.save_aggregate(aggregate, metadata)
    end

    # TODO: with_new_aggregate
  end
end
