module EventFramework
  Error = Class.new(StandardError)

  autoload :Types, 'types'
  autoload :DomainEvent, 'domain_event'
  autoload :Event, 'event'
  autoload :EventHandlers, 'event_handlers'
  autoload :EventStore, 'event_store'
  autoload :Command, 'command'
  autoload :CommandHandler, 'command_handler'
  autoload :CommandHandlerBuilder, 'command_handler_builder'
  autoload :Metadata, 'metadata'
  autoload :Aggregate, 'aggregate'
  autoload :Repository, 'repository'

  class << self
    attr_accessor :config

    # See https://github.com/rails/rails/blob/20c91119903f70eb19aed33fe78417789dbf070f/railties/lib/rails.rb#L72
    def environment
      ENV['RAILS_ENV'] || ENV['RACK_ENV'] || 'development'
    end

    def configure
      self.config ||= Configuration.new
      yield config
    end
  end

  class Configuration
    attr_accessor :database_url, :event_namespace_class

    def initialize
      @event_namespace_class = Object
    end
  end
end

# TODO: Move this config to domains/ as it's app specific
Events = Module.new

EventFramework.configure do |config|
  config.event_namespace_class = Events
end

require_relative "../config/environments/#{EventFramework.environment}"
