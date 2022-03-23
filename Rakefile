# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubygems/package'
require_relative './ext/asherah/native_downloader'

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

def current_filename
  @current_filename ||=
    begin
      require 'cobhan'
      Class.new.extend(Cobhan).library_file_name('libasherah')
    end
end

def current_platform
  @distribution ||= DISTRIBUTIONS.detect { |_k, v| v.include?(current_filename) }
  @distribution.first
end

def native_build(platform, file_names)
  puts "Building gem for #{platform}"

  pkg_dir = File.join(__dir__, 'pkg')
  FileUtils.mkdir_p(pkg_dir)

  gem_root_dir = File.join(__dir__, 'tmp', platform)
  FileUtils.rm_rf(gem_root_dir, verbose: true)
  FileUtils.mkdir_p(gem_root_dir, verbose: true)

  # Copy files to tmp gem dir
  gemspec = Bundler.load_gemspec('asherah.gemspec')
  gemspec.files.each do |file|
    dir = File.dirname(file)
    filename = File.basename(file)
    FileUtils.mkdir_p(File.join(gem_root_dir, dir))
    FileUtils.copy_file(file, File.join(gem_root_dir, dir, filename))
  end

  # Set platform for native gem build
  gemspec.platform = Gem::Platform.new(platform)

  native_dir = 'lib/asherah/native'
  FileUtils.cd(gem_root_dir, verbose: true) do
    FileUtils.mkdir_p(native_dir)
    file_names.each do |file_name|
      native_file_path = File.join(native_dir, file_name)

      # Download native file
      NativeDownloader.download(gem_root_dir, file_name)

      # Add native file in gemspec
      gemspec.files << native_file_path
    end

    package = Gem::Package.build(gemspec)
    FileUtils.mv package, File.join(pkg_dir, package)
  end
end

namespace :native do
  desc 'Build all native gems'
  task :build do
    DISTRIBUTIONS.each do |platform, file_names|
      native_build(platform, file_names)
    end
  end

  namespace :build do
    DISTRIBUTIONS.each do |platform, file_names|
      desc "Build native gem for #{platform}"
      task :"#{platform}" do
        native_build(platform, file_names)
      end
    end
  end

  namespace :current do
    desc 'Download asherah binary for current platform'
    task :download do
      root_dir = File.expand_path('.', __dir__)
      NativeDownloader.download(root_dir, current_filename)
    end

    desc 'Build native gem for current platform'
    task :build do
      native_build(current_platform, DISTRIBUTIONS[current_platform])
    end

    desc 'Smoke test native gem for current platform'
    task smoke: :build do
      platform = current_platform
      gemspec = Bundler.load_gemspec('asherah.gemspec')
      gemspec.platform = Gem::Platform.new(platform)

      sh('gem uninstall asherah')
      sh("gem install pkg/#{gemspec.file_name}")
      sh('ruby spec/smoke_test.rb')
    end
  end
end

task :version do
  puts Asherah::VERSION
end
