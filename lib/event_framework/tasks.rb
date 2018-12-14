module EventFramework
  module Tasks
    autoload :Runner, 'event_framework/tasks/runner'

    # Used by Tasks::Runner to source configuration
    class << self
      attr_accessor :root_module
      attr_accessor :registered_contexts
    end
  end
end
