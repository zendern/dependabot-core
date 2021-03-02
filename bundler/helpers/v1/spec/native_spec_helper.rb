# frozen_string_literal: true

require "rspec/its"
require "webmock/rspec"
require "byebug"

# Bundler monkey patches
require "definition_ruby_version_patch"
require "definition_bundler_version_patch"
require "git_source_patch"

require "functions"

RSpec.configure do |config|
  config.color = true
  config.order = :rand
  config.mock_with(:rspec) { |mocks| mocks.verify_partial_doubles = true }
  config.raise_errors_for_deprecations!
end

def fixture(*name)
  File.read(File.join("spec", "fixtures", File.join(*name)))
end
