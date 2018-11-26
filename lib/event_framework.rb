require 'dry/configurable'

module EventFramework
  extend Dry::Configurable

  # "Our" base-class for all framework-specific errors
  Error = Class.new(StandardError)

  # An exception raised within a currently-executing command that
  # can trigger a re-execution of the command.
  RetriableException = Class.new(Error)

  autoload :Aggregate, 'event_framework/aggregate'
  autoload :Bookmark, 'event_framework/bookmark'
  autoload :BookmarkReadonly, 'event_framework/bookmark_readonly'
  autoload :BookmarkRepository, 'event_framework/bookmark_repository'
  autoload :Command, 'event_framework/command'
  autoload :CommandHandler, 'event_framework/command_handler'
  autoload :ControllerHelpers, 'event_framework/controller_helpers'
  autoload :DomainEvent, 'event_framework/domain_event'
  autoload :DomainStruct, 'event_framework/domain_struct'
  autoload :Event, 'event_framework/event'
  autoload :EventHandlerRegistry, 'event_framework/event_handler_registry'
  autoload :EventProcessor, 'event_framework/event_processor'
  autoload :EventProcessorSupervisor, 'event_framework/event_processor_supervisor'
  autoload :EventProcessorWorker, 'event_framework/event_processor_worker'
  autoload :EventProcessorMonitor, 'event_framework/event_processor_monitor'
  autoload :EventStore, 'event_framework/event_store'
  autoload :Metadata, 'event_framework/metadata'
  autoload :ParameterStoreDatabaseConfiguration, 'event_framework/parameter_store_database_configuration'
  autoload :Projector, 'event_framework/projector'
  autoload :Reactor, 'event_framework/reactor'
  autoload :Repository, 'event_framework/repository'
  autoload :StagedEvent, 'event_framework/staged_event'
  autoload :Types, 'event_framework/types'

  # See https://github.com/rails/rails/blob/20c91119903f70eb19aed33fe78417789dbf070f/railties/lib/rails.rb#L72
  def self.environment
    ENV['RAILS_ENV'] || ENV['RACK_ENV'] || 'development'
  end

  # The root path of the EventFramework files
  def self.root
    Pathname.new(__dir__).join('..')
  end

  # The Module from which Event definitions are sourced; defaults to Object
  setting :event_namespace_class, Object

  # The full URL used to connect to the database
  # e.g. postgres://localhost/database_name
  setting :database_url

  # An Object that responds to `.call` that is called with an array of new
  # Events any time an event or list of events is saved.
  setting :after_sink_hook, -> (events) {}

  # An Object that responds to `.call` that is called with an error and an
  # event any time an error is raised in an event processor.
  setting :event_processor_error_reporter, -> (error, event) {}
end

require_relative "../config/environments/#{EventFramework.environment}"
