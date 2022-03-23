# frozen_string_literal: true

require 'open-uri'
require 'fileutils'
require 'digest'
require 'yaml'

# Downloads native file and verifies checksum
class NativeDownloader
  CHECKSUMS_FILE = File.expand_path('checksums.yml', __dir__)
  CHECKSUMS = YAML.load_file(CHECKSUMS_FILE)
  VERSION = CHECKSUMS.fetch('version')
  RETRIES = 3
  RETRY_DELAY = 1

  class << self
    def download(root_dir, file_name)
      lib_dir = File.join(root_dir, 'lib/asherah')
      abort "#{lib_dir} does not exist" unless File.exist?(lib_dir)

      native_dir = "#{lib_dir}/native"
      FileUtils.mkdir_p(native_dir)

      file_path = File.join(native_dir, file_name)
      abort "#{file_path} already exists" if File.exist?(file_path)

      download_file(file_path, file_name)
    end

    private

    def download_file(file_path, file_name)
      checksum = CHECKSUMS.fetch(file_name) { abort "Unsupported platform for #{file_name}" }
      tries = 0

      begin
        tries += 1
        url = "https://github.com/godaddy/asherah-cobhan/releases/download/#{VERSION}/#{file_name}"
        puts "Downloading #{url}"
        content = URI.parse(url).open.read

        sha256 = Digest::SHA256.hexdigest(content)
        abort "Could not verify checksum of #{file_name}" if sha256 != checksum

        File.binwrite(file_path, content)
      rescue Net::OpenTimeout, Net::ReadTimeout => e
        if tries <= RETRIES
          puts "Got #{e.class}... retrying in #{RETRY_DELAY} seconds"
          sleep RETRY_DELAY
          retry
        else
          raise e
        end
      end
    end
  end
end
