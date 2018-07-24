require 'dry-configurable'

module EventFramework
  extend Dry::Configurable

  Error = Class.new(StandardError)

  autoload :Types, 'types'
  autoload :Event, 'event'
  autoload :EventStore, 'event_store'

  # See https://github.com/rails/rails/blob/20c91119903f70eb19aed33fe78417789dbf070f/railties/lib/rails.rb#L72
  def self.environment
    ENV['RAILS_ENV'] || ENV['RACK_ENV'] || 'development'
  end

  # the Module from which Event definitions are sourced
  setting :event_namespace_class

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
