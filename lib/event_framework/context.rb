require 'dry/container'
require 'dry/inflector'
require 'sequel'

module EventFramework
  module Context
    NoSuchDatabaseRegisteredError = Class.new(Error)

    # Extends the given module with the behavior required for it to be used
    # as a Context
    def self.initialize_context(context_module, path_to_root)
      context_module.extend Environment
      context_module.extend DatabaseRegistration

      context_module.define_singleton_method :root do
        @root ||= Pathname.new(path_to_root).join('..')
      end

      context_module.define_singleton_method :paths do
        @paths ||= Paths.new(root)
      end

      context_module.define_singleton_method :container do
        @container ||= Dry::Container.new
      end
    end

    class Paths
      def initialize(root)
        @root = root
      end

      def config
        @root.join('config')
      end

      def db(database_name)
        @root.join('db', database_name)
      end
    end

    module Environment
      # See https://github.com/rails/rails/blob/20c91119903f70eb19aed33fe78417789dbf070f/railties/lib/rails.rb#L72
      def environment
        ENV['RAILS_ENV'] || ENV['RACK_ENV'] || 'development'
      end
    end

    module DatabaseRegistration
      def register_database(label)
        container.namespace(:databases) do
          register label.to_sym, DatabaseConnection.new(label.to_sym)
        end
      end

      def database(label)
        container.resolve("databases.#{label}")
      rescue Dry::Container::Error
        raise NoSuchDatabaseRegisteredError, "No database has been regisered for #{label}"
      end
    end
  end
end
