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
    attr_accessor :database_url
  end
end

require_relative "../config/environments/#{EventFramework.environment}"
