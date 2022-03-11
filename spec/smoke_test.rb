# frozen_string_literal: true

def report_error(message)
  abort("\e[31m#{message}\e[0m")
end

require 'asherah'

Asherah.configure do |config|
  config.service_name = 'gem'
  config.product_id = 'sable'
  config.kms = 'static'
  config.metastore = 'memory'
end

partition_id = 'user_1'
data = 'test'
data_row_record = Asherah.encrypt(partition_id, data)
decrypted_data = Asherah.decrypt(partition_id, data_row_record)

report_error('Smoke test failed') if decrypted_data != data
