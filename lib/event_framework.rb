require 'dry/configurable'

module EventFramework
  extend Dry::Configurable

  Error = Class.new(StandardError)

  # An exception raised within a currently-executing command that
  # can trigger a re-execution of the command.
  RetriableException = Class.new(Error)

  AfterSinkHook = -> (events) {}

  autoload :Bookmark, 'bookmark'
  autoload :BookmarkRepository, 'bookmark_repository'
  autoload :Types, File.join(File.dirname(__FILE__), 'types')
  autoload :DomainEvent, 'domain_event'
  autoload :Event, File.join(File.dirname(__FILE__), 'event')
  autoload :EventHandlerRegistry, 'event_handler_registry'
  autoload :EventProcessor, 'event_processor'
  autoload :EventProcessorSupervisor, 'event_processor_supervisor'
  autoload :EventProcessorWorker, 'event_processor_worker'
  autoload :EventStore, 'event_store'
  autoload :Command, 'command'
  autoload :CommandHandler, 'command_handler'
  autoload :ControllerHelpers, 'controller_helpers'
  autoload :Metadata, 'metadata'
  autoload :Aggregate, 'aggregate'
  autoload :Projector, 'projector'
  autoload :Reactor, 'reactor'
  autoload :Repository, 'repository'
  autoload :StagedEvent, 'staged_event'
  autoload :DomainStruct, 'domain_struct'
  autoload :ParameterStoreDatabaseConfiguration, 'parameter_store_database_configuration'

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

require_relative "../config/environments/#{EventFramework.environment}"
