module EventFramework
  class Reactor < EventProcessor
    extend Forwardable

    def handle_event(event)
      self.class.event_handlers.for(event.domain_event.type).each do |handler|
        instance_exec(event.aggregate_id, event.domain_event, event.metadata, event.id, &handler)
      end
    end

    private

    def_delegators 'with_aggregate_proxy', :with_aggregate, :with_new_aggregate
    private :with_aggregate, :with_new_aggregate

    def with_aggregate_proxy
      WithAggregateProxy.new(Repository.new)
    end
  end
end
