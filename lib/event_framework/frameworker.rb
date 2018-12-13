require 'thor'
require 'dry/inflector'

module EventFramework
  class Frameworker < Thor
    class << self
      attr_accessor :root_module
    end

    def self.exit_on_failure?
      true
    end

    desc "show", "shows a module"
    def show(mod)
      inflector = Dry::Inflector.new

      module_name = inflector.camelize(mod)

      puts Frameworker.root_module.const_get(module_name, false).paths.config
    end
  end
end
