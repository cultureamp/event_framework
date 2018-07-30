require 'dry/configurable'

module EventFramework
  extend Dry::Configurable

  Error = Class.new(StandardError)

  autoload :Types, 'types'
  autoload :DomainEvent, 'domain_event'
  autoload :Event, 'event'
  autoload :EventHandlerRegistry, 'event_handler_registry'
  autoload :EventStore, 'event_store'
  autoload :Command, 'command'
  autoload :CommandHandler, 'command_handler'
  autoload :CommandHandlerBuilder, 'command_handler_builder'
  autoload :Metadata, 'metadata'
  autoload :Aggregate, 'aggregate'
  autoload :Repository, 'repository'
  autoload :StagedEvent, 'staged_event'

  # See https://github.com/rails/rails/blob/20c91119903f70eb19aed33fe78417789dbf070f/railties/lib/rails.rb#L72
  def self.environment
    ENV['RAILS_ENV'] || ENV['RACK_ENV'] || 'development'
  end

  # the Module from which Event definitions are sourced; defaults to Object
  setting :event_namespace_class, Object

  # the full URL used to connect to the database
  # e.g. postgres://localhost/database_name
  setting :database_url
end

# TODO: Move this config to domains/ as it's app specific
Events = Module.new

EventFramework.configure do |config|
  config.event_namespace_class = Events
end

require_relative "../config/environments/#{EventFramework.environment}"
