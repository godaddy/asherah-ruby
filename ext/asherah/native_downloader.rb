require 'net/http'
require 'open-uri'
require 'fileutils'

class NativeDownloader
  ASHERAH_VERSION = 'v0.4.3'
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
      tries = 0

      begin
        tries += 1
        url = "https://github.com/godaddy/asherah-cobhan/releases/download/#{ASHERAH_VERSION}/#{file_name}"
        puts "Downloading #{url}"
        File.binwrite(file_path, URI.parse(url).open.read)
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
