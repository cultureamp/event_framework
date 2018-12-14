module EventFramework
  module Tasks
    module Generators
      autoload :MigrationGenerator, 'event_framework/tasks/generators/migration_generator'

      def self.templates_root
        EventFramework.root.join('lib', 'templates')
      end
    end
  end
end
