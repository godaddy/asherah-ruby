# frozen_string_literal: true

require 'asherah'
require 'base64'

SERVICE_NAME      = ENV.fetch('ASHERAH_SERVICE_NAME')
PRODUCT_ID        = ENV.fetch('ASHERAH_PRODUCT_NAME')
KMS               = ENV.fetch('ASHERAH_KMS_MODE')
DB_NAME           = ENV.fetch('TEST_DB_NAME')
DB_USER           = ENV.fetch('TEST_DB_USER')
DB_PASS           = ENV.fetch('TEST_DB_PASSWORD')
DB_PORT           = ENV.fetch('TEST_DB_PORT')
DB_HOST           = ENV.fetch('TEST_DB_HOSTNAME', '127.0.0.1')
CONNECTION_STRING = "#{DB_USER}:#{DB_PASS}@tcp(#{DB_HOST}:#{DB_PORT})/#{DB_NAME}?tls=skip-verify"
TMP_DIR           = '/tmp/'
FILE_NAME         = 'ruby_encrypted'
METASTORE         = 'rdbms'

Before do |_scenario|
  Asherah.configure do |config|
    config.service_name = SERVICE_NAME
    config.product_id = PRODUCT_ID
    config.metastore = METASTORE
    config.sql_metastore_db_type = 'mysql'
    config.connection_string = CONNECTION_STRING
    config.kms = KMS
    config.enable_session_caching = true
    config.verbose = true
  end
end

After do |_scenario|
  Asherah.shutdown
end
