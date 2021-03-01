# frozen_string_literal: true

require "bundler/compact_index_client"
require "bundler/compact_index_client/updater"

TMP_DIR_PATH = File.expand_path("../tmp", __dir__)

# Duplicated in lib/dependabot/bundler/file_updater/lockfile_updater.rb
# TODO: Stop sanitizing the lockfile once we have bundler 2 installed
LOCKFILE_ENDING = /(?<ending>\s*(?:RUBY VERSION|BUNDLED WITH).*)/m.freeze

def project_dependency_files(project)
  project_path = File.expand_path(File.join("spec/fixtures/projects", project))
  Dir.chdir(project_path) do
    # NOTE: Include dotfiles (e.g. .npmrc)
    files = Dir.glob("**/*", File::FNM_DOTMATCH)
    files = files.select { |f| File.file?(f) }
    files.map do |filename|
      content = File.read(filename)
      if filename == "Gemfile.lock"
        content = content.gsub(LOCKFILE_ENDING, "")
      end
      {
        name: filename,
        content: content
      }
    end
  end
end

RSpec.shared_context "in a temporary bundler directory" do
  let(:project_name) { "Gemfile" }

  let(:tmp_path) do
    Dir.mkdir(TMP_DIR_PATH) unless Dir.exist?(TMP_DIR_PATH)
    dir = Dir.mktmpdir("native_helper_spec_", TMP_DIR_PATH)
    Pathname.new(dir).expand_path
  end

  before do
    project_dependency_files(project_name).each do |file|
      File.write(File.join(tmp_path, file[:name]), file[:content])
    end
  end

  def in_tmp_folder(&block)
    Dir.chdir(tmp_path, &block)
  end
end

RSpec.shared_context "without caching rubygems" do
  before do
    # Stub Bundler to stop it using a cached versions of Rubygems
    allow_any_instance_of(Bundler::CompactIndexClient::Updater).
      to receive(:etag_for).and_return("")
  end
end

RSpec.shared_context "stub rubygems compact index" do
  include_context "without caching rubygems"

  before do
    # Stub the Rubygems index
    stub_request(:get, "https://index.rubygems.org/versions").
      to_return(
        status: 200,
        body: fixture("ruby", "rubygems_responses", "index")
      )

    # Stub the Rubygems response for each dependency we have a fixture for
    fixtures =
      Dir[File.join("spec", "fixtures", "ruby", "rubygems_responses", "info-*")]
    fixtures.each do |path|
      dep_name = path.split("/").last.gsub("info-", "")
      stub_request(:get, "https://index.rubygems.org/info/#{dep_name}").
        to_return(
          status: 200,
          body: fixture("ruby", "rubygems_responses", "info-#{dep_name}")
        )
    end
  end
end
