# frozen_string_literal: true

require 'bundler/setup'
require 'webmock/rspec'
# require 'json-schema'
# require_relative "support/have_attributes_matcher"

require 'simplecov'
if RSpec.configuration.files_to_run.size > 1
  SimpleCov.start do
    track_files 'lib/**/*.rb'
    add_filter '/lib/komtet/version.rb' # already loaded by bundler, so 0% coverage in report
    add_filter %r{^/spec/}
  end
end

require 'komtet'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
