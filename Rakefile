# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

# Default spec task excludes integration tests to avoid CI failures
RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = '--tag ~integration'
end

# Task to run all tests including integration tests
RSpec::Core::RakeTask.new(:spec_all)

require 'rubocop/rake_task'

RuboCop::RakeTask.new

desc 'Download the binary for the current platform'
task :download do
  tmp_dir = 'tmp'
  FileUtils.mkdir_p(tmp_dir)
  FileUtils.cd(tmp_dir, verbose: true) do
    system('ruby ../ext/asherah/extconf.rb')
  end
end

task default: %i[spec rubocop]
task spec: :download

desc 'Print current version'
task :version do
  puts Asherah::VERSION
end

Rake.add_rakelib 'tasks'
