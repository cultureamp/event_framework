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
      context_module.extend MagicDependencies

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
      NAMESPACE_PREFIX = 'databases'.freeze

      def register_database(label)
        container.namespace(NAMESPACE_PREFIX) do
          register label.to_sym, DatabaseConnection.new(label.to_sym)
        end
      end

      def database(label)
        container.resolve("databases.#{label}")
      rescue Dry::Container::Error
        raise NoSuchDatabaseRegisteredError, "No database has been regisered for #{label}"
      end

      def databases
        container
          .to_enum
          .select { |key, _value| key.split('.').first == NAMESPACE_PREFIX }
          .map(&:last)
      end
    end

    module MagicDependencies
      def enable_magic_dependencies!
        container.register('event_store.event_type_resolver') do
          EventStore::EventTypeResolver.new(event_context_module: self)
        end

        container.register('event_store.sink') do
          EventStore::Sink.new(
            database: database(:event_store).connection,
            event_type_resolver: container.resolve('event_store.event_type_resolver'),
          )
        end

        container.register('event_store.source') do
          EventStore::Source.new(
            database: database(:event_store).connection,
            event_type_resolver: container.resolve('event_store.event_type_resolver'),
          )
        end

        container.register('repository') do
          Repository.new(
            sink: container.resolve('event_store.sink'),
            source: container.resolve('event_store.source'),
          )
        end
      end
    end
  end
end
