require 'dry/inflector'
require 'thor'

module EventFramework
  module Tasks
    class Runner < Thor
      def self.exit_on_failure?
        true
      end

      private

      def context_module(name)
        inflector = Dry::Inflector.new

        EventFramework::Tasks.root_module.const_get(inflector.camelize(name), false)
      end
    end
  end
end
