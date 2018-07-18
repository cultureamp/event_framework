require 'sequel'
require 'erb'
require 'yaml'

module EventFramework
  class EventStore
    # See https://github.com/rails/rails/blob/20c91119903f70eb19aed33fe78417789dbf070f/railties/lib/rails.rb#L72
    def self.environment
      ENV["RAILS_ENV"] || ENV["RACK_ENV"] || "development"
    end

    def self.config
      @@config ||= {}
      settings_file_path = File.join(File.dirname(__FILE__), '../', 'config', 'database.yml')
      settings_content = ERB.new(File.read(settings_file_path)).result
      @@config[environment] ||= YAML.load(settings_content)[environment]
    end

    def self.database_url
      @@_database_url ||= config['database_url']
    end

    def self.database
      @@database ||= Sequel.connect(database_url)
      @@database.extension :pg_json
      @@database
    end
  end
end
