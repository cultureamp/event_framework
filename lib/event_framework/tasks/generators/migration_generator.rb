require 'thor'
require 'thor/group'

module EventFramework
  module Tasks
    module Generators
      class MigrationGenerator < Thor::Group
        include Thor::Actions

        argument :context_name
        argument :database_name

        class_option :migration_name, default: 'migration', alias: 'name'

        def self.source_root
          Generators.templates_root
        end

        def create_migration_file
          inflector = Dry::Inflector.new

          timestamp_prefix = Time.now.utc.strftime('%Y%m%d%H%M%S')
          file_name = "#{timestamp_prefix}_#{inflector.underscore(options[:migration_name])}.rb"

          template 'migration.erb', context_module(context_name).paths.db(database_name).join('migrations', file_name)
        end

        private

        def context_module(name)
          inflector = Dry::Inflector.new

          EventFramework::Tasks.root_module.const_get(inflector.camelize(name), false)
        end
      end
    end
  end
end
