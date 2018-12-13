require 'dry/container'
require 'dry/inflector'
require 'sequel'

module EventFramework
  module Context
    # Extends the given module with the behavior required for it to be used
    # as a Context
    def self.initialize_context(context_module, path_to_root)
      context_module.extend Environment

      context_module.define_singleton_method :root do
        Pathname.new(path_to_root).join('..')
      end
    end

    module Environment
      # See https://github.com/rails/rails/blob/20c91119903f70eb19aed33fe78417789dbf070f/railties/lib/rails.rb#L72
      def environment
        ENV['RAILS_ENV'] || ENV['RACK_ENV'] || 'development'
      end
    end
  end
end
