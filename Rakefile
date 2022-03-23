# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

require 'rubocop/rake_task'

RuboCop::RakeTask.new

desc 'Download the binary for the current platform'
task :download do
  FileUtils.cd('tmp', verbose: true) do
    system('ruby ../ext/asherah/extconf.rb')
  end
end

task default: %i[spec rubocop]
task spec: :download

desc 'Print current version'
task :version do
  puts Asherah::VERSION
end
