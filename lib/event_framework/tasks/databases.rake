require_relative '../tasks/database_tasks'

namespace :event_store do
  namespace :db do
    task :environment do
    end

    task load_config: :environment do
    end

    desc "Checks to see if EventFramework has been configured; exits cleanly if not"
    task check_configuration: :load_config do
      EventFramework::Tasks::DatabaseTasks.check_configuration
    end

    desc "Run the migrate and schema-dump tasks; Set VERSION in Env to choose which migration to target"
    task migrate: ["migrate:run", "schema:dump"]

    namespace :migrate do
      desc "Perform Migrations; Set VERSION in Env to choose which migration to target"
      task run: :check_configuration do
        EventFramework::Tasks::DatabaseTasks.migrate
      end

      desc "Create a database migration, Pass in the NAME Env var to set the filename"
      task create: :check_configuration do
        EventFramework::Tasks::DatabaseTasks.create_migration
      end
    end

    desc "Reset database"
    task reset: [:drop, :create, :migrate]

    desc "Create database"
    task create: :check_configuration do
      EventFramework::Tasks::DatabaseTasks.create
    end

    desc "Drop database"
    task drop: :check_configuration do
      EventFramework::Tasks::DatabaseTasks.drop
    end

    namespace :schema do
      desc "Dump database schema"
      task :dump do
        EventFramework::Tasks::DatabaseTasks.dump_schema
      end
    end
  end
end

namespace :projection do
  namespace :db do
    task :environment do
    end

    task load_config: :environment do
    end

    desc "Checks to see if EventFramework has been configured; exits cleanly if not"
    task check_configuration: :load_config do
      EventFramework::Tasks::DatabaseTasks.check_configuration
    end

    desc "Run the migrate and schema-dump tasks; Set VERSION in Env to choose which migration to target"
    task migrate: ["migrate:run", "schema:dump"]

    namespace :migrate do
      desc "Perform Migrations; Set VERSION in Env to choose which migration to target"
      task run: :check_configuration do
        EventFramework::Tasks::DatabaseTasks.migrate
      end

      desc "Create a database migration, Pass in the NAME Env var to set the filename"
      task create: :check_configuration do
        EventFramework::Tasks::DatabaseTasks.create_migration
      end
    end

    desc "Reset database"
    task reset: [:drop, :create, :migrate]

    desc "Create database"
    task create: :check_configuration do
      EventFramework::Tasks::DatabaseTasks.create
    end

    desc "Drop database"
    task drop: :check_configuration do
      EventFramework::Tasks::DatabaseTasks.drop
    end

    namespace :schema do
      desc "Dump database schema"
      task :dump do
        EventFramework::Tasks::DatabaseTasks.dump_schema
      end
    end
  end
end
