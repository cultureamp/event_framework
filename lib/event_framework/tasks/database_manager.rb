require 'sequel/core'

module EventFramework
  module Tasks
    class DatabaseManager
      DatabaseAlreadyExistsError = Class.new(Error)

      attr_reader :connection

      def initialize(connection)
        @connection = connection
      end

      def create
        Sequel.connect(root_database_uri.to_s) do |db|
          db.execute "CREATE DATABASE #{db_name}"
        end
      rescue Sequel::DatabaseError => error
        if error.cause.is_a?(PG::DuplicateDatabase)
          raise DatabaseAlreadyExistsError
        else
          raise
        end
      end

      private

      def root_database_uri
        connection.uri.tap { |u| u.path = '/postgres' }
      end

      def db_name
        File.basename(connection.uri.path)
      end
    end
  end
end
