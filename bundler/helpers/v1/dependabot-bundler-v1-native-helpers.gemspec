# frozen_string_literal: true

require "find"

Gem::Specification.new do |spec|
  spec.name         = "dependabot-bundler-v1-native-helpers"
  spec.summary      = "Ruby (bundler) native helpers for dependabot"
  spec.version      = "0.0.0"
  spec.description  = "Automated dependency management for Ruby, JavaScript, "\
                      "Python, PHP, Elixir, Rust, Java, .NET, Elm and Go"

  spec.author       = "Dependabot"
  spec.email        = "support@dependabot.com"
  spec.homepage     = "https://github.com/dependabot/dependabot-core"
  spec.license      = "Nonstandard" # License Zero Prosperity Public License

  spec.require_paths = %w(lib monkey_patches)

  spec.required_ruby_version = ">= 2.5.0"
  spec.required_rubygems_version = ">= 2.7.3"

  spec.add_development_dependency "byebug", "~> 11.0"
  spec.add_development_dependency "rspec", "~> 3.8"
  spec.add_development_dependency "rspec-its", "~> 1.2"
  spec.add_development_dependency "rubocop", "~> 1.11.0"
  spec.add_development_dependency "vcr", "6.0.0"
  spec.add_development_dependency "webmock", "~> 3.4"
end
