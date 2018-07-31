require 'dotenv'
Dotenv.load '../.env'

namespace :event_store do
  namespace :db do
    desc "Run migrations"
    task :migrate, [:version] do |_t, args|
      require "sequel/core"
      require_relative 'lib/event_framework'

      Sequel.extension :migration

      version = args[:version].to_i if args[:version]

      Sequel.connect(EventFramework.config.database_url) do |db|
        Sequel::Migrator.run(db, "db/migrations", target: version)
      end
    end

    namespace :migrate do
      desc "Create a database migration, Pass in the NAME Env var to set the filename"
      task :create do
        require 'sequel/core'
        Sequel.extension :inflector
        timestamp_prefix = Time.now.utc.strftime("%Y%m%d%H%M%S")
        migration_name = ENV["NAME"] || 'migration'

        file_name = "#{timestamp_prefix}_#{migration_name.underscore}.rb"

        File.open("db/migrations/#{file_name}", 'w') do |f|
          f << <<~MIGRATION
            Sequel.migration do
              up do
              end

              down do
              end
            end
          MIGRATION
        end
      end
    end

    desc "Reset database"
    task reset: [:drop, :create, :migrate]

    desc "Create database"
    task :create do
      require "sequel/core"
      require_relative 'lib/event_framework'

      database_uri      = URI.parse(EventFramework.config.database_url)
      root_database_uri = URI.parse(EventFramework.config.database_url).tap { |u| u.path = '/postgres' }

      db_name = File.basename(database_uri.path)

      Sequel.connect(root_database_uri.to_s) do |db|
        db.execute "CREATE DATABASE #{db_name}"
      end
    end

    desc "Drop database"
    task :drop do
      require "sequel/core"
      require_relative 'lib/event_framework'

      database_uri      = URI.parse(EventFramework.config.database_url)
      root_database_uri = URI.parse(EventFramework.config.database_url).tap { |u| u.path = '/postgres' }

      db_name = File.basename(database_uri.path)

      Sequel.connect(root_database_uri.to_s) do |db|
        db.execute "DROP DATABASE IF EXISTS #{db_name}"
      end
    end

    namespace :schema do
      desc "Dump database schema"
      task :dump do
        require_relative 'lib/tasks/schema_dump'

        SchemaDump.call(EventFramework.config.database_url, filename: 'db/structure.sql')
      end
    end
  end
end
