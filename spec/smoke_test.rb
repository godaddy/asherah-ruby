require 'asherah'
require 'rspec'

load 'spec/asherah_spec.rb'

RSpec::Core::Runner.invoke

# NOTE: The following runs the specs against the source which is not what we want.
# RSpec::Core::Runner.run(['spec/asherah_spec.rb'])
