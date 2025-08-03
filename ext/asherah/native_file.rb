# frozen_string_literal: true

require 'open-uri'
require 'fileutils'
require 'digest'
require 'yaml'
require 'cobhan'

# Downloads native file and verifies checksum
class NativeFile
  LIB_NAME = 'libasherah'
  ROOT_DIR = File.expand_path('../../', __dir__)
  CHECKSUMS_FILE = File.expand_path('checksums.yml', __dir__)
  CHECKSUMS = YAML.load_file(CHECKSUMS_FILE)
  VERSION = CHECKSUMS.fetch('version')
  RETRIES = 3
  RETRY_DELAY = 1

  class << self
    def download(
      file_name: Class.new.extend(Cobhan).library_file_name(LIB_NAME),
      dir: File.join(ROOT_DIR, 'lib/asherah/native')
    )
      file_path = File.join(dir, file_name)
      if File.exist?(file_path)
        puts "#{file_path} already exists ... skipping download"
        return
      end

      checksum = CHECKSUMS.fetch(file_name) do
        abort "Unsupported platform #{RUBY_PLATFORM}"
      end

      content = download_content(file_name)

      sha256 = Digest::SHA256.hexdigest(content)
      abort "Could not verify checksum of #{file_name}" if sha256 != checksum

      FileUtils.mkdir_p(dir)
      File.binwrite(file_path, content)
    end

    private

    def download_content(file_name)
      tries = 0

      begin
        tries += 1
        # Validate VERSION format to prevent URL injection
        raise ArgumentError, "Invalid version format: #{VERSION}" unless VERSION.match?(/\A[a-zA-Z0-9._-]+\z/)
        
        # Validate file_name to prevent path traversal
        raise ArgumentError, "Invalid file name: #{file_name}" unless file_name.match?(/\A[a-zA-Z0-9._-]+\z/)
        
        # Use URI.join for safer URL construction
        base_url = "https://github.com/godaddy/asherah-cobhan/releases/download/#{VERSION}/"
        url = URI.join(base_url, file_name).to_s
        puts "Downloading #{url}"
        URI.parse(url).open.read
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
