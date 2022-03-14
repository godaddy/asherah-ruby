# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubygems/package'
require 'open-uri'

RSpec::Core::RakeTask.new(:spec)

require 'rubocop/rake_task'

RuboCop::RakeTask.new

task default: %i[spec rubocop]

DISTRIBUTIONS = {
  'x86_64-linux' => ['libasherah-x64.so'],
  'x86_64-darwin' => ['libasherah-x64.dylib'],
  'aarch64-linux' => ['libasherah-arm64.so'],
  'arm64-darwin' => ['libasherah-arm64.dylib']
}.freeze

def native_build(platform, native_files)
  puts "Building gem for #{platform}"

  pkg_dir = File.join(__dir__, 'pkg')
  FileUtils.mkdir_p(pkg_dir)

  tmp_gem_dir = File.join(__dir__, 'tmp', platform)
  FileUtils.rm_rf(tmp_gem_dir, verbose: true)
  FileUtils.mkdir_p(tmp_gem_dir, verbose: true)

  # Copy files to tmp gem dir
  gemspec = Bundler.load_gemspec('asherah.gemspec')
  gemspec.files.each do |file|
    dir = File.dirname(file)
    filename = File.basename(file)
    FileUtils.mkdir_p(File.join(tmp_gem_dir, dir))
    FileUtils.copy_file(file, File.join(tmp_gem_dir, dir, filename))
  end

  # Set platform for native gem build and remove extentions
  gemspec.platform = Gem::Platform.new(platform)

  native_dir = 'lib/asherah/native'
  FileUtils.cd(tmp_gem_dir, verbose: true) do
    FileUtils.mkdir_p(native_dir)
    native_files.each do |native_file|
      native_file_path = File.join(native_dir, native_file)
      gemspec.files << native_file_path

      File.open(native_file_path, 'wb') do |file|
        url = "https://github.com/godaddy/asherah-cobhan/releases/download/current/#{native_file}"
        puts "Downloading #{url}"
        file << URI.parse(url).open.read
      end
    end

    package = Gem::Package.build gemspec
    FileUtils.mv package, File.join(pkg_dir, package)
  end
end

namespace :native do
  desc 'Build all native gems'
  task :build do
    DISTRIBUTIONS.each do |platform, native_files|
      native_build(platform, native_files)
    end
  end

  namespace :build do
    DISTRIBUTIONS.each do |platform, native_files|
      desc "Build native gem for #{platform}"
      task :"#{platform}" do
        native_build(platform, native_files)
      end
    end
  end

  namespace :smoke do
    require 'cobhan'

    filename = Class.new.extend(Cobhan).library_file_name('libasherah')
    platform, _files = DISTRIBUTIONS.detect { |_k, v| v.include?(filename) }

    desc "Smoke test native gem on #{platform} platform"
    task "#{platform}": :"build:#{platform}" do
      gemspec = Bundler.load_gemspec('asherah.gemspec')
      gemspec.platform = Gem::Platform.new(platform)

      sh("gem install pkg/#{gemspec.file_name}")
      sh('ruby spec/smoke_test.rb')
    end
  end
end

task :version do
  puts Asherah::VERSION
end
