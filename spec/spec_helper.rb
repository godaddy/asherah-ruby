# frozen_string_literal: true

if ENV.fetch('COVERAGE', nil) == 'true'
  require 'simplecov'
  require 'simplecov-console'

  SimpleCov.formatter = SimpleCov::Formatter::Console
  SimpleCov.start do
    add_filter 'spec/kms_spec.rb'
  end
end

require 'dotenv'
# Only load env files if they exist to avoid CI failures
env_files = ['.env', '.env.secrets'].select { |file| File.exist?(file) }
Dotenv.overload(*env_files) if env_files.any?

require 'asherah'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
