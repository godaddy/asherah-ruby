# frozen_string_literal: true

RSpec.describe 'Asherah error handling' do
  describe 'uninitialized state errors' do
    # Skip the before(:each) hook that initializes Asherah
    before(:each) { }
    after(:each) { }

    it 'raises NotInitialized error when encrypting without configuration' do
      expect {
        Asherah.encrypt('partition', 'data')
      }.to raise_error(Asherah::Error::NotInitialized)
    end

    it 'raises NotInitialized error when decrypting without configuration' do
      expect {
        Asherah.decrypt('partition', '{"fake": "json"}')
      }.to raise_error(Asherah::Error::NotInitialized)
    end

    # Note: set_env does not require initialization as environment
    # variables may need to be set before Asherah is configured

    it 'raises NotInitialized error when shutting down without configuration' do
      expect {
        Asherah.shutdown
      }.to raise_error(Asherah::Error::NotInitialized)
    end
  end

  describe 'double initialization protection' do
    before :each do
      Asherah.configure do |config|
        config.service_name = 'test'
        config.product_id = 'test'
        config.kms = 'test-debug-static'
        config.metastore = 'test-debug-memory'
      end
    end

    after :each do
      Asherah.shutdown
    end

    it 'raises AlreadyInitialized error on second configure attempt' do
      expect {
        Asherah.configure do |config|
          config.service_name = 'test2'
          config.product_id = 'test2'
          config.kms = 'test-debug-static'
          config.metastore = 'test-debug-memory'
        end
      }.to raise_error(Asherah::Error::AlreadyInitialized)
    end
  end

  describe 'error result handling' do
    it 'converts negative error codes to appropriate exceptions' do
      # Test each error code mapping
      expect { Asherah::Error.check_result!(-100, 'test') }.to raise_error(Asherah::Error::NotInitialized, 'test (-100)')
      expect { Asherah::Error.check_result!(-101, 'test') }.to raise_error(Asherah::Error::AlreadyInitialized, 'test (-101)')
      expect { Asherah::Error.check_result!(-102, 'test') }.to raise_error(Asherah::Error::GetSessionFailed, 'test (-102)')
      expect { Asherah::Error.check_result!(-103, 'test') }.to raise_error(Asherah::Error::EncryptFailed, 'test (-103)')
      expect { Asherah::Error.check_result!(-104, 'test') }.to raise_error(Asherah::Error::DecryptFailed, 'test (-104)')
      expect { Asherah::Error.check_result!(-105, 'test') }.to raise_error(Asherah::Error::BadConfig, 'test (-105)')
    end

    it 'raises StandardError for unknown error codes' do
      expect { Asherah::Error.check_result!(-999, 'unknown') }.to raise_error(StandardError, 'unknown (-999)')
    end

    it 'does not raise for non-negative results' do
      expect { Asherah::Error.check_result!(0, 'success') }.not_to raise_error
      expect { Asherah::Error.check_result!(1, 'positive') }.not_to raise_error
    end
  end
end