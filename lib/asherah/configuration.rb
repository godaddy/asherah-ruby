# frozen_string_literal: true

module Asherah
  # Configuration and lifecycle management
  module Configuration
    def configure
      raise Asherah::Error::AlreadyInitialized if @initialized

      config = Config.new
      yield config
      config.validate!
      @intermediated_key_overhead_bytesize = config.product_id.bytesize + config.service_name.bytesize

      config_buffer = string_to_cbuffer(config.to_json)

      result = SetupJson(config_buffer)
      Error.check_result!(result, 'SetupJson failed')
      @initialized = true
    ensure
      config_buffer&.free
    end

    def shutdown
      raise Asherah::Error::NotInitialized unless @initialized

      Shutdown()
      @initialized = false
    end
  end
end
