require_relative "lib/event_framework/version"

Gem::Specification.new do |spec|
  spec.name = "event_framework"
  spec.version = EventFramework::VERSION
  spec.authors = ["Odin Dutton"]
  spec.email = ["odin.dutton@cultureamp.com"]

  spec.summary = "An event framework"
  spec.description = spec.summary
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path("..", __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "pg"
  spec.add_dependency "sequel"
  spec.add_dependency "sequel_pg"
  spec.add_dependency "dry-auto_inject"
  spec.add_dependency "dry-struct", "~> 1.0"
  spec.add_dependency "dry-types", "~> 1.0"
  spec.add_dependency "dry-configurable"
  spec.add_dependency "dry-container"
  spec.add_dependency "dry-validation", "~> 1.0"
  spec.add_dependency "forked"
  spec.add_dependency "daemons"
  spec.add_dependency "transproc"
  spec.add_dependency "thor"
  spec.add_dependency "dogapi"
  spec.add_dependency "dry-monads"
end
