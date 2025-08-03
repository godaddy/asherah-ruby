# Asherah Ruby Troubleshooting Guide

This guide helps diagnose and resolve common issues when using the Asherah Ruby gem.

## Table of Contents
- [Common Errors](#common-errors)
- [Performance Issues](#performance-issues)
- [Configuration Problems](#configuration-problems)
- [Platform-Specific Issues](#platform-specific-issues)
- [Debugging Techniques](#debugging-techniques)
- [FAQ](#faq)

## Common Errors

### NotInitialized Error

**Error Message**: `Asherah::Error::NotInitialized`

**Cause**: Attempting to encrypt/decrypt before configuring Asherah.

**Solution**:
```ruby
# Ensure configuration happens before any operations
Asherah.configure do |config|
  config.service_name = 'my_service'
  config.product_id = 'my_product'
  config.kms = 'static'
  config.metastore = 'memory'
end

# Now you can encrypt/decrypt
encrypted = Asherah.encrypt('partition', 'data')
```

**Common Scenarios**:
- Rails: Configuration not in initializer
- Testing: Setup not in `before` block
- Background jobs: Worker process not configured

### AlreadyInitialized Error

**Error Message**: `Asherah::Error::AlreadyInitialized`

**Cause**: Attempting to configure Asherah multiple times in the same process.

**Solution**:
```ruby
# Configure only once per process
unless defined?(@asherah_configured)
  Asherah.configure do |config|
    # ... configuration ...
  end
  @asherah_configured = true
end

# Or handle the error
begin
  Asherah.configure { |c| ... }
rescue Asherah::Error::AlreadyInitialized
  # Already configured, continue
end
```

### ArgumentError: Invalid Parameters

**Error Messages**:
- `partition_id cannot be nil`
- `data must be a String`
- `partition_id too long (max 1KB)`

**Solution**:
```ruby
# Validate inputs before encryption
def safe_encrypt(partition_id, data)
  raise ArgumentError, 'partition_id required' if partition_id.nil?
  raise ArgumentError, 'data required' if data.nil?
  
  # Convert to strings
  partition = partition_id.to_s
  data_str = data.to_s
  
  # Check size limits
  raise ArgumentError, 'partition too long' if partition.bytesize > 1024
  raise ArgumentError, 'data too large' if data_str.bytesize > 100 * 1024 * 1024
  
  Asherah.encrypt(partition, data_str)
end
```

### DecryptFailed Error

**Error Message**: `Asherah::Error::DecryptFailed`

**Common Causes**:
1. Wrong partition ID used for decryption
2. Corrupted encrypted data
3. KMS key no longer accessible
4. Metastore data loss

**Debugging Steps**:
```ruby
# Verify partition ID matches
def debug_decrypt(partition_id, encrypted_json)
  puts "Partition ID: #{partition_id}"
  puts "Encrypted data present: #{!encrypted_json.nil?}"
  puts "Encrypted data size: #{encrypted_json.bytesize}"
  
  # Validate JSON structure
  begin
    parsed = JSON.parse(encrypted_json)
    puts "Has Data field: #{parsed.key?('Data')}"
    puts "Has Key field: #{parsed.key?('Key')}"
  rescue JSON::ParserError => e
    puts "Invalid JSON: #{e.message}"
  end
  
  # Attempt decrypt
  Asherah.decrypt(partition_id, encrypted_json)
rescue => e
  puts "Decrypt failed: #{e.class} - #{e.message}"
  raise
end
```

### Connection Errors (RDBMS Metastore)

**Error Messages**:
- `connection refused`
- `timeout expired`
- `authentication failed`

**Solutions**:

1. **Verify connection string format**:
```ruby
# MySQL
config.connection_string = 'user:pass@tcp(host:3306)/dbname'

# PostgreSQL  
config.connection_string = 'host=localhost port=5432 user=user password=pass dbname=db'

# With connection pool limits
config.connection_string = 'user:pass@tcp(host:3306)/dbname?max_connections=10'
```

2. **Test database connectivity**:
```ruby
# Test connection outside Asherah
require 'mysql2'
client = Mysql2::Client.new(
  host: 'localhost',
  username: 'user',
  password: 'pass',
  database: 'dbname'
)
client.query("SELECT 1")
```

3. **Check firewall/security groups**: Ensure database port is accessible

### AWS KMS Errors

**Error Messages**:
- `The security token included in the request is invalid`
- `User: arn:aws:iam::... is not authorized to perform: kms:Decrypt`
- `Invalid keyId`

**Solutions**:

1. **Verify AWS credentials**:
```bash
# Test AWS CLI access
aws kms describe-key --key-id your-key-id
```

2. **Check IAM permissions**:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:GenerateDataKey",
        "kms:DescribeKey"
      ],
      "Resource": "arn:aws:kms:region:account:key/*"
    }
  ]
}
```

3. **Verify KMS key policy** allows your IAM user/role

## Performance Issues

### Slow Encryption/Decryption

**Symptoms**: Operations taking >100ms

**Diagnostic Steps**:
```ruby
require 'benchmark'

# Measure operation time
time = Benchmark.realtime do
  Asherah.encrypt('partition', 'data')
end
puts "Encryption took: #{(time * 1000).round(2)}ms"
```

**Solutions**:

1. **Enable session caching**:
```ruby
config.enable_session_caching = true
config.session_cache_max_size = 1000
config.session_cache_duration = 300
```

2. **Use connection pooling** for RDBMS:
```ruby
config.connection_string = "#{base_string}?max_connections=25&max_idle_connections=10"
```

3. **Batch operations** when possible:
```ruby
# Instead of multiple calls
data.each { |item| Asherah.encrypt(partition, item) }

# Batch with same partition
encrypted_items = data.map { |item| Asherah.encrypt(partition, item) }
```

### Memory Usage Issues

**Symptoms**: Growing memory usage, OOM errors

**Diagnostic Tools**:
```ruby
# Monitor object allocation
require 'objspace'
ObjectSpace.trace_object_allocations_start

# ... run operations ...

ObjectSpace.dump_all(output: File.open('heap.json', 'w'))
```

**Solutions**:

1. **Reduce cache size**:
```ruby
config.session_cache_max_size = 100  # Reduce from default
```

2. **Process large datasets in batches**:
```ruby
User.find_in_batches(batch_size: 100) do |batch|
  batch.each do |user|
    # Process one user at a time
    encrypted = Asherah.encrypt(user.id.to_s, user.data)
    # Save and release memory
  end
  GC.start # Force garbage collection between batches
end
```

## Configuration Problems

### Invalid Configuration Values

**Error**: `Asherah::Error::ConfigError`

**Common Issues**:

1. **Missing required fields**:
```ruby
# Minimum required configuration
Asherah.configure do |config|
  config.service_name = 'service'  # Required
  config.product_id = 'product'    # Required
  config.kms = 'static'           # Required
  config.metastore = 'memory'     # Required
end
```

2. **Invalid KMS type**:
```ruby
# Valid KMS types
config.kms = 'static'  # Testing only
config.kms = 'aws'     # Production
config.kms = 'test-debug-static'  # Debug mode
```

3. **Missing AWS configuration**:
```ruby
# AWS KMS requires additional config
config.kms = 'aws'
config.preferred_region = 'us-west-2'  # Required
config.region_map = {                  # Required
  'us-west-2' => 'arn:aws:kms:...'
}
```

### Environment-Specific Issues

**Problem**: Different behavior in development vs production

**Solution**: Use environment-specific configuration:
```ruby
Asherah.configure do |config|
  config.service_name = 'my_app'
  config.product_id = 'my_product'
  
  case ENV['APP_ENV']
  when 'production'
    config.kms = 'aws'
    config.metastore = 'rdbms'
    config.verbose = false
  when 'staging'
    config.kms = 'aws'
    config.metastore = 'memory'
    config.verbose = true
  else
    config.kms = 'static'
    config.metastore = 'memory'
    config.verbose = true
  end
end
```

## Platform-Specific Issues

### macOS Apple Silicon (M1/M2)

**Error**: `incompatible architecture`

**Solution**:
```bash
# Ensure native binary is for arm64
file lib/asherah/native/libasherah.dylib
# Should show: Mach-O 64-bit dynamically linked shared library arm64

# Reinstall gem
gem uninstall asherah
gem install asherah
```

### Linux Library Dependencies

**Error**: `cannot open shared object file`

**Solution**:
```bash
# Check library dependencies
ldd lib/asherah/native/libasherah.so

# Install missing libraries (Ubuntu/Debian)
sudo apt-get update
sudo apt-get install libc6
```

### Docker Containers

**Issue**: Binary compatibility in containers

**Solution** - Multi-stage Dockerfile:
```dockerfile
# Build stage
FROM ruby:3.0 AS builder
WORKDIR /app
COPY Gemfile* ./
RUN bundle install

# Runtime stage
FROM ruby:3.0-slim
WORKDIR /app
COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY . .

# Ensure binary is downloaded for container architecture
RUN bundle exec rake download
```

## Debugging Techniques

### Enable Verbose Logging

```ruby
Asherah.configure do |config|
  # ... other config ...
  config.verbose = true  # Enable detailed logging
end
```

### Capture Detailed Errors

```ruby
class AsherahDebugger
  def self.debug_operation(&block)
    yield
  rescue => e
    puts "Error Class: #{e.class}"
    puts "Error Message: #{e.message}"
    puts "Backtrace:"
    puts e.backtrace.first(10).join("\n")
    
    # Additional context
    puts "\nAsherah Configuration:"
    puts "- Initialized: #{defined?(@initialized) ? @initialized : 'unknown'}"
    
    raise
  end
end

# Usage
AsherahDebugger.debug_operation do
  Asherah.encrypt('partition', 'data')
end
```

### Test Configuration

```ruby
# Verify configuration without operations
def test_asherah_config
  begin
    Asherah.configure do |config|
      config.service_name = 'test'
      config.product_id = 'test'
      config.kms = 'test-debug-static'
      config.metastore = 'test-debug-memory'
      config.verbose = true
    end
    puts "✓ Configuration successful"
    
    # Test basic operation
    result = Asherah.encrypt('test', 'data')
    puts "✓ Encryption successful"
    
    decrypted = Asherah.decrypt('test', result)
    puts "✓ Decryption successful"
    
    Asherah.shutdown
    puts "✓ Shutdown successful"
    
    true
  rescue => e
    puts "✗ Test failed: #{e.message}"
    false
  end
end
```

## FAQ

### Q: Can I change configuration after initialization?
**A**: No, Asherah must be shutdown and reconfigured. This requires application restart.

### Q: How do I rotate encryption keys?
**A**: Keys are automatically rotated based on `expire_after` setting. Old keys remain readable.

### Q: Can I decrypt data if I lose the metastore?
**A**: No, the metastore contains essential key information. Always backup your metastore.

### Q: Is it safe to log encrypted data?
**A**: Yes, but avoid logging partition IDs with encrypted data as this could aid attacks.

### Q: How do I handle decrypt failures gracefully?
**A**: Implement fallback behavior:
```ruby
def safe_decrypt(partition_id, encrypted_data, default = nil)
  Asherah.decrypt(partition_id, encrypted_data)
rescue Asherah::Error::DecryptFailed => e
  Rails.logger.error("Decryption failed: #{e.message}")
  default
end
```

### Q: Can I use Asherah across different programming languages?
**A**: Yes, Asherah has implementations for multiple languages that can share encrypted data.

### Q: What happens during network partitions with AWS KMS?
**A**: Operations will fail after timeout. Implement retry logic with exponential backoff.

### Q: How do I estimate metastore storage requirements?
**A**: Each key record is ~1-2KB. Calculate: (partitions × keys_per_partition × 2KB) + 50% overhead