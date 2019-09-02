module TestDomain
  EventFramework::BoundedContext.initialize_bounded_context self, Pathname.new(__dir__).join("..")

  register_database :event_store
  register_database :projections

  build_command_dependency_chain!
end

base_uri = URI.parse(ENV.fetch("EVENT_SOURCED_DOMAINS_DATABASE_URL", "postgres://localhost/"))

TestDomain.database(:event_store).connection_url = base_uri.tap { |u| u.path = "/event_framework_event_store_test" }.to_s
TestDomain.database(:projections).connection_url = base_uri.tap { |u| u.path = "/event_framework_projections_test" }.to_s
