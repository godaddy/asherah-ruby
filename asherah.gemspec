# frozen_string_literal: true

require_relative 'lib/asherah/version'

Gem::Specification.new do |spec|
  spec.name = 'asherah'
  spec.version = Asherah::VERSION
  spec.authors = ['GoDaddy']
  spec.email = ['oss@godaddy.com']

  spec.summary = 'Application Layer Encryption SDK'
  spec.description = <<~DESCRIPTION
    Asherah is an application-layer encryption SDK that provides advanced
    encryption features and defense in depth against compromise.
  DESCRIPTION

  spec.homepage = 'https://github.com/godaddy/asherah-ruby'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 2.5.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/godaddy/asherah-ruby'
  spec.metadata['changelog_uri'] = 'https://github.com/godaddy/asherah-ruby/blob/main/CHANGELOG.md'
  spec.metadata['rubygems_mfa_required'] = 'true'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
end
