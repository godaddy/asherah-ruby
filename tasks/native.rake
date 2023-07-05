# frozen_string_literal: true

require 'rubygems/package'
require_relative '../ext/asherah/native_file'

ROOT_DIR = File.join(__dir__, '../')
NATIVE_DIR = 'lib/asherah/native'
DISTRIBUTIONS = {
  'x86_64-linux' => 'libasherah-x64.so',
  'x86_64-darwin' => 'libasherah-x64.dylib',
  'aarch64-linux' => 'libasherah-arm64.so',
  'arm64-darwin' => 'libasherah-arm64.dylib'
}.freeze

def build_native_gem(platform, file_name)
  puts "Building gem for #{platform}"

  pkg_dir = File.join(ROOT_DIR, 'pkg')
  FileUtils.mkdir_p(pkg_dir)

  tmp_gem_dir = File.join(ROOT_DIR, 'tmp', platform)
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

  # Set platform for native gem build
  gemspec.platform = Gem::Platform.new(platform)

  FileUtils.cd(tmp_gem_dir, verbose: true) do
    FileUtils.mkdir_p(NATIVE_DIR)

    native_file_path = File.join(NATIVE_DIR, file_name)

    # Download native file
    NativeFile.download(file_name: file_name, dir: NATIVE_DIR)

    # Add native file in gemspec
    gemspec.files << native_file_path

    package = Gem::Package.build(gemspec)
    FileUtils.mv package, File.join(pkg_dir, package)
  end
end

namespace :native do
  desc 'Build all native gems'
  task :build do
    DISTRIBUTIONS.each do |platform, file_name|
      build_native_gem(platform, file_name)
    end
  end

  namespace :build do
    DISTRIBUTIONS.each do |platform, file_name|
      desc "Build native gem for #{platform}"
      task :"#{platform}" do
        build_native_gem(platform, file_name)
      end
    end
  end
end
