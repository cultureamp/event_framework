require 'dry/inflector'
require 'thor'

module EventFramework
  module Tasks
    class Runner < Thor
      def self.exit_on_failure?
        true
      end

      desc "create_database CONTEXT DATABASE_NAME", "Creates the PostgreSQL database for the indicated context/database"
      def create_database(context_name, database_name)
        connection = context_module(context_name).database(database_name.to_sym)

        DatabaseManager.new(connection).create
      rescue DatabaseManager::DatabaseAlreadyExistsError
        puts "#{context_name}/#{database_name} already exists, skipping"
      end

      private

      def context_module(name)
        inflector = Dry::Inflector.new

        EventFramework::Tasks.root_module.const_get(inflector.camelize(name), false)
      end
    end
  end
end
