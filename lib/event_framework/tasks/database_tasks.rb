require_relative 'postgresql_database_tasks'

module EventFramework
  module Tasks
    class DatabaseAlreadyExists < StandardError; end # :nodoc:
    class DatabaseNotSupported < StandardError; end # :nodoc:
    module DatabaseTasks
      module_function

      attr_writer :database_directory, :migrations_path, :environment, :adapter
      attr_accessor :database_url

      LOCAL_HOSTS = ["127.0.0.1", "localhost"]

      def database_directory
        @database_directory ||= EventFramework.config.database_directory
      end

      def migrations_path
        @migrations_path ||= EventFramework.config.migrations_path
      end

      def environment
        @environment ||= 'development'
      end

      def adapter
        @adapter ||= 'postgresql'
      end

      def register_task(pattern, task)
        @tasks ||= {}
        @tasks[pattern] = task
      end

      register_task(/postgresql/, "EventFramework::Tasks::PostgreSQLDatabaseTasks")

      def check_configuration
        if database_url.nil?
          warn "No DATABASE_URL configured in #{environment.inspect}; exiting."
          exit
        end
      end

      def create
        class_for_adapter(adapter).new(database_url).create
        $stdout.puts "Created database '#{db_name}'"
      rescue DatabaseAlreadyExists
        warn "Database '#{db_name}' already exists"
      rescue Exception => error # rubocop:disable Lint/RescueException
        warn error
        warn "Couldn't create database for #{db_name}"
        raise
      end

      def drop
        class_for_adapter(adapter).new(database_url).drop
        $stdout.puts "Dropped database '#{db_name}'"
      rescue Exception => error # rubocop:disable Lint/RescueException
        warn error
        warn "Couldn't drop database '#{db_name}'"
        raise
      end

      def migrate
        adapter_tasks = class_for_adapter(adapter).new(database_url)
        adapter_tasks.check_target_version(target_version)

        $stdout.puts "Migrating in #{environment.inspect} environment..."
        adapter_tasks.migrate(migrations_path: migrations_path, target_version: target_version)
      rescue Exception => error # rubocop:disable Lint/RescueException
        warn error
        warn "Couldn't migrate database '#{db_name}'"
        raise
      end

      def create_migration
        class_for_adapter(adapter)
          .new(database_url)
          .create_migration(migrations_path: migrations_path, migration_name: ENV.fetch('NAME', 'migration'))
      end

      def dump_schema
        require_relative 'schema_dump'
        SchemaDump.call(database_url, filename: "#{database_directory}/structure.sql") if environment == 'development'
      end

      def target_version
        ENV["VERSION"].to_i if ENV["VERSION"] && !ENV["VERSION"].empty?
      end

      private

      def class_for_adapter(adapter)
        require 'dry/core/inflector'

        _key, task = @tasks.each_pair.detect { |pattern, _task| adapter[pattern] }
        raise DatabaseNotSupported, "Rake tasks not supported by '#{adapter}' adapter" unless task

        task.is_a?(String) ? Dry::Core::Inflector.constantize(task) : task
      end

      def database_uri
        URI.parse(database_url)
      end

      def db_name
        File.basename(database_uri.path)
      end
    end
  end
end
