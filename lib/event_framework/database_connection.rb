require 'sequel'

Sequel::Database.load_adapter :postgres

module EventFramework
  # Encapsulates the configuration and interface required to establish a
  # connection to a PostgreSQL database
  class DatabaseConnection < DelegateClass(Sequel::Postgres::Database)
    MissingConnectionURLError = Class.new(Error)

    # A Symbol, identifying the name / role / nature of this database
    # within it's parent context
    attr_reader :label

    # A String, containing a URL to be used to connect to the database
    attr_accessor :connection_url

    def initialize(label)
      @label = label.to_sym
    end

    def __getobj__
      connection
    end

    def connection
      raise MissingConnectionURLError if connection_url.nil?

      @_connection ||= Sequel.connect(connection_url).tap do |database|
        database.extension :pg_json
      end
    end

    def uri
      raise MissingConnectionURLError if connection_url.nil?

      URI(connection_url)
    end
  end
end
