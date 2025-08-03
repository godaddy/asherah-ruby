# Asherah Ruby Configuration Guide

This guide provides detailed information about configuring the Asherah Ruby gem for various deployment scenarios.

## Table of Contents
- [Basic Configuration](#basic-configuration)
- [KMS Providers](#kms-providers)
- [Metastore Options](#metastore-options)
- [Session Caching](#session-caching)
- [Key Rotation](#key-rotation)
- [Production Best Practices](#production-best-practices)

## Basic Configuration

The minimal configuration requires setting up a KMS provider and metastore:

```ruby
require 'asherah'

Asherah.configure do |config|
  config.service_name = 'my_service'     # Your service name
  config.product_id = 'my_product'       # Your product identifier
  config.kms = 'static'                  # KMS provider (static for testing)
  config.metastore = 'memory'            # Metastore type (memory for testing)
end
```

## KMS Providers

### Static KMS (Development/Testing)

The static KMS provider uses a hardcoded master key. **Never use in production!**

```ruby
config.kms = 'static'
```

### AWS KMS (Production)

For production use with AWS Key Management Service:

```ruby
config.kms = 'aws'
config.preferred_region = 'us-west-2'
config.region_map = {
  'us-west-2' => 'arn:aws:kms:us-west-2:123456789012:key/12345678-1234-1234-1234-123456789012',
  'us-east-1' => 'arn:aws:kms:us-east-1:123456789012:key/87654321-4321-4321-4321-210987654321'
}
```

#### AWS Authentication

The gem uses the standard AWS SDK credential chain:
1. Environment variables (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`)
2. EC2 instance profile credentials
3. AWS credentials file (`~/.aws/credentials`)
4. ECS task role credentials

#### Multi-Region Setup

For high availability, configure multiple regions:

```ruby
config.region_map = {
  'us-west-2' => 'arn:aws:kms:us-west-2:...',
  'us-east-1' => 'arn:aws:kms:us-east-1:...',
  'eu-west-1' => 'arn:aws:kms:eu-west-1:...'
}
config.preferred_region = 'us-west-2'  # Primary region for new encryptions
```

## Metastore Options

### Memory Metastore (Testing)

Stores keys in memory only. Data is lost on restart:

```ruby
config.metastore = 'memory'
```

### RDBMS Metastore (Production)

Persists keys in a relational database:

```ruby
config.metastore = 'rdbms'
config.connection_string = 'username:password@tcp(hostname:3306)/database'
config.sql_metastore_db_type = 'mysql'  # or 'postgres', 'oracle'
```

#### Database Schema

Create the required table before using RDBMS metastore:

```sql
-- MySQL
CREATE TABLE encryption_key (
  id         VARCHAR(255) NOT NULL,
  created    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  key_record TEXT         NOT NULL,
  PRIMARY KEY (id, created),
  INDEX (created)
);

-- PostgreSQL
CREATE TABLE encryption_key (
  id         VARCHAR(255) NOT NULL,
  created    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  key_record TEXT         NOT NULL,
  PRIMARY KEY (id, created)
);
CREATE INDEX idx_created ON encryption_key (created);
```

#### Connection String Formats

- **MySQL**: `username:password@tcp(hostname:3306)/database?parseTime=true`
- **PostgreSQL**: `host=hostname port=5432 user=username password=password dbname=database sslmode=require`
- **Oracle**: `username/password@hostname:1521/service_name`

### DynamoDB Metastore

For AWS-native deployments:

```ruby
config.metastore = 'dynamodb'
config.dynamo_db_region = 'us-west-2'
config.dynamo_db_table_name = 'AsherahKeyTable'
config.enable_region_suffix = true  # For regional tables
```

#### DynamoDB Table Schema

```yaml
AttributeDefinitions:
  - AttributeName: Id
    AttributeType: S
  - AttributeName: Created
    AttributeType: N
KeySchema:
  - AttributeName: Id
    KeyType: HASH
  - AttributeName: Created
    KeyType: RANGE
```

## Session Caching

Improve performance by caching encryption sessions:

```ruby
config.enable_session_caching = true
config.session_cache_max_size = 1000    # Maximum number of cached sessions
config.session_cache_duration = 300     # Cache duration in seconds (5 minutes)
```

### Cache Tuning Guidelines

- **High-throughput applications**: Increase `session_cache_max_size`
- **Memory-constrained environments**: Reduce cache size and duration
- **Security-sensitive applications**: Reduce `session_cache_duration`

## Key Rotation

Configure automatic key rotation policies:

```ruby
config.expire_after = 86400      # Key expiration in seconds (24 hours)
config.check_interval = 3600     # How often to check for expired keys (1 hour)
```

### Rotation Best Practices

1. **Set appropriate expiration times**:
   - Highly sensitive data: 1-7 days
   - Standard data: 30-90 days
   - Compliance requirements may dictate specific periods

2. **Monitor rotation metrics**:
   - Track key creation frequency
   - Monitor decryption failures after rotation
   - Alert on rotation failures

## Production Best Practices

### 1. Environment-Specific Configuration

```ruby
Asherah.configure do |config|
  config.service_name = ENV.fetch('SERVICE_NAME')
  config.product_id = ENV.fetch('PRODUCT_ID')
  
  case ENV['RAILS_ENV']
  when 'production'
    config.kms = 'aws'
    config.metastore = 'rdbms'
    config.connection_string = ENV.fetch('DATABASE_URL')
    # Production-specific settings
  when 'staging'
    config.kms = 'aws'
    config.metastore = 'memory'
    # Staging-specific settings
  else
    config.kms = 'static'
    config.metastore = 'memory'
    # Development settings
  end
end
```

### 2. Connection Pool Configuration

When using RDBMS metastore with connection pools:

```ruby
# Ensure Asherah connections don't exhaust the pool
config.connection_string = "#{base_connection_string}?max_connections=10"
```

### 3. Monitoring and Logging

Enable verbose logging for troubleshooting:

```ruby
config.verbose = true  # Enable detailed logging
```

Implement custom monitoring:

```ruby
# Wrap Asherah calls with monitoring
def encrypt_with_monitoring(partition_id, data)
  start_time = Time.now
  result = Asherah.encrypt(partition_id, data)
  
  StatsD.timing('asherah.encrypt.duration', Time.now - start_time)
  StatsD.increment('asherah.encrypt.count')
  
  result
rescue => e
  StatsD.increment('asherah.encrypt.error')
  raise
end
```

### 4. Error Handling

Implement robust error handling:

```ruby
begin
  encrypted_data = Asherah.encrypt(partition_id, sensitive_data)
rescue Asherah::Error::NotInitialized => e
  # Handle initialization errors
  logger.error("Asherah not initialized: #{e.message}")
  raise
rescue Asherah::Error::EncryptFailed => e
  # Handle encryption failures
  logger.error("Encryption failed: #{e.message}")
  # Consider fallback behavior
rescue => e
  # Handle unexpected errors
  logger.error("Unexpected Asherah error: #{e.message}")
  raise
end
```

### 5. Thread Safety

The Asherah Ruby gem is thread-safe after initialization:

```ruby
# Initialize once at application startup
Asherah.configure do |config|
  # ... configuration ...
end

# Safe to use from multiple threads
threads = 10.times.map do |i|
  Thread.new do
    100.times do |j|
      Asherah.encrypt("partition_#{i}", "data_#{j}")
    end
  end
end
threads.each(&:join)
```

### 6. Shutdown Handling

Properly shutdown Asherah on application termination:

```ruby
at_exit do
  Asherah.shutdown if defined?(Asherah)
end

# Or in Rails
class Application < Rails::Application
  config.after_initialize do
    Asherah.configure { |c| ... }
  end
  
  at_exit { Asherah.shutdown }
end
```

## Troubleshooting

### Common Issues

1. **"NotInitialized" errors**: Ensure `Asherah.configure` is called before any encrypt/decrypt operations

2. **"AlreadyInitialized" errors**: Configure Asherah only once per process

3. **Database connection errors**: Verify connection string format and database accessibility

4. **AWS KMS errors**: Check IAM permissions and KMS key policies

5. **Performance issues**: Enable session caching and tune cache parameters

### Debug Configuration

For development debugging:

```ruby
Asherah.configure do |config|
  config.service_name = 'debug_service'
  config.product_id = 'debug_product'
  config.kms = 'test-debug-static'        # Special debug KMS
  config.metastore = 'test-debug-memory'  # Special debug metastore
  config.verbose = true                   # Enable all logging
end
```