namespace :event_store do
  namespace :db do
    desc "Run migrations"
    task :migrate, [:version] do |_t, args|
      require "sequel/core"
      require_relative 'lib/event_framework'
      require_relative 'lib/database'
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
      require_relative 'lib/event_framework'
      require_relative 'lib/database'
      db_name = File.basename(URI.parse(EventFramework.config.database_url).path)
      Sequel.connect('postgres:///template1') do |db|
        db.execute "CREATE DATABASE #{db_name}"
      end
    end

    desc "Drop database"
    task :drop do
      require_relative 'lib/event_framework'
      require_relative 'lib/database'
      db_name = File.basename(URI.parse(EventFramework.config.database_url).path)
      Sequel.connect('postgres:///template1') do |db|
        db.execute "DROP DATABASE IF EXISTS #{db_name}"
      end
    end
  end
end
