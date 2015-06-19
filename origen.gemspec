# coding: utf-8
config = File.expand_path('../config', __FILE__)
require "#{config}/version"

Gem::Specification.new do |spec|
  spec.name          = "origen"
  spec.version       = Origen::VERSION
  spec.authors       = ["Stephen McGinty"]
  spec.email         = ["stephen.f.mcginty@gmail.com"]
  spec.summary       = %q{A Semiconductor Developer's Kit}
  #spec.homepage      = "http://"

  spec.required_ruby_version     = '>= 1.9.3'
  spec.required_rubygems_version = '>= 1.8.11'

  spec.files         = Dir["lib/**/*.rb", "lib/**/*.erb", "templates/**/*", "config/**/*.rb",
                           "bin/*", "helpers/**/*.rb", "vendor/**/*", "lib/tasks/**/*.rake",
                           "config/**/*.yml", "config/**/*.policy",
                           "spec/format/rgen_formatter.rb", "source_setup"
                          ]
  spec.executables   = ["origen", "rgen"]
  spec.require_paths = ["lib"]

  # Don't add any logic to runtime dependencies, for example to install a specific gem
  # based on Ruby version.
  # Rubygems / Bundler do not support this and you will need to find another way around it.
  spec.add_runtime_dependency "activesupport", "~> 4.1"
  spec.add_runtime_dependency "colored", "~> 1.2"
  spec.add_runtime_dependency "net-ldap", "~> 0.9"
  spec.add_runtime_dependency "httparty", "~>0.13"
  spec.add_runtime_dependency "bundler", "~> 1.7"
  spec.add_runtime_dependency "nokogiri", "1.6.4.1"
  spec.add_runtime_dependency "rspec", "~>3"
  spec.add_runtime_dependency "rspec-legacy_formatters", "~>1"
  spec.add_runtime_dependency "thor", "~>0.19"
  spec.add_runtime_dependency "nanoc", "~>3.7"
  spec.add_runtime_dependency "kramdown", "~>1.5"
  spec.add_runtime_dependency "rubocop", "0.30"
  spec.add_runtime_dependency "coderay", "~>1.1"
  spec.add_runtime_dependency "rake", "~>10"
  spec.add_runtime_dependency "geminabox", "0.12.4"
  spec.add_runtime_dependency "pry", "~>0.10"
  spec.add_runtime_dependency "yard", "~>0.8"
  spec.add_runtime_dependency "simplecov", "~>0.9"
  spec.add_runtime_dependency "log4r", "~> 1.1", "~>1.1.10"
  spec.add_runtime_dependency "scrub_rb", "~> 1.0"

  # Conditional logic in development dependencies is allowed as this is only evaluated when
  # the app is run from its own workspace
  unless RUBY_PLATFORM == 'i386-mingw32'
    spec.add_development_dependency "stackprof", "~>0"
  end
  spec.add_development_dependency "rgen_core_support", "0.2.0pre0"
  spec.add_development_dependency "doc_helpers", ">= 1.7.0"
  spec.add_development_dependency "loco"
  spec.add_development_dependency "rgen_testers", "0.3.0.pre33"
end