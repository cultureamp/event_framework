require 'dry/configurable'

module EventFramework
  extend Dry::Configurable

  Error = Class.new(StandardError)

  # An exception raised within a currently-executing command that
  # can trigger a re-execution of the command.
  RetriableException = Class.new(Error)

  AfterSinkHook = -> (events) {}

  autoload :Types, File.join(File.dirname(__FILE__), 'types')
  autoload :DomainEvent, 'domain_event'
  autoload :Event, File.join(File.dirname(__FILE__), 'event')
  autoload :EventHandlerRegistry, 'event_handler_registry'
  autoload :EventProcessor, 'event_processor'
  autoload :EventStore, 'event_store'
  autoload :Command, 'command'
  autoload :CommandHandler, 'command_handler'
  autoload :ControllerHelpers, 'controller_helpers'
  autoload :Metadata, 'metadata'
  autoload :Aggregate, 'aggregate'
  autoload :Repository, 'repository'
  autoload :StagedEvent, 'staged_event'

  # See https://github.com/rails/rails/blob/20c91119903f70eb19aed33fe78417789dbf070f/railties/lib/rails.rb#L72
  def self.environment
    ENV['RAILS_ENV'] || ENV['RACK_ENV'] || 'development'
  end

  # The Module from which Event definitions are sourced; defaults to Object
  setting :event_namespace_class, Object

  # The full URL used to connect to the database
  # e.g. postgres://localhost/database_name
  setting :database_url

  # An Object that responds to `.call` that is called with an array of new
  # Events any time an event or list of events is saved.
  setting :after_sink_hook, AfterSinkHook
end

# TODO: Move this config to domains/ as it's app specific
Events = Module.new

EventFramework.configure do |config|
  config.event_namespace_class = Events
end

require_relative "../config/environments/#{EventFramework.environment}"
