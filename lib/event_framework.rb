module EventFramework
  Error = Class.new(StandardError)

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
