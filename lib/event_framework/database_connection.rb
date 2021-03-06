require "uri"
require "sequel"

Sequel::Database.load_adapter :postgres

module EventFramework
  # Encapsulates the configuration and interface required to establish a
  # connection to a PostgreSQL database.
  #
  # You'll notice that this inherits from a Delegate; primarily, this is done
  # to further encapsulate the API and avoid having references to `.connection`
  # throughout the codebase.
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
      __raise__ MissingConnectionURLError if connection_url.nil?

      # Max connections should match the number of threads being used by our
      # server. We're currently (2020-06-32) using Unicorn which uses separate
      # processes for workers--not threads (unlike Puma). This means we should
      # only need a single connection.
      @_connection ||= Sequel.connect(connection_url, max_connections: 1).tap do |database|
        database.extension :pg_json
      end
    end

    def uri
      raise MissingConnectionURLError if connection_url.nil?

      URI.parse(connection_url)
    end

    def inspect
      "#<EventFramework::DatabaseConnection label=#{label.inspect}>"
    end

    alias to_s inspect
  end
end
