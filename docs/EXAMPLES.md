# Asherah Ruby Examples

This document provides practical examples of using the Asherah Ruby gem in various scenarios.

## Table of Contents
- [Basic Usage](#basic-usage)
- [Rails Integration](#rails-integration)
- [Sinatra Integration](#sinatra-integration)
- [Background Jobs](#background-jobs)
- [Multi-Tenant Applications](#multi-tenant-applications)
- [Microservices](#microservices)
- [Data Migration](#data-migration)
- [Testing Strategies](#testing-strategies)

## Basic Usage

### Simple Encryption/Decryption

```ruby
require 'asherah'

# Configure once at startup
Asherah.configure do |config|
  config.service_name = 'my_app'
  config.product_id = 'my_product'
  config.kms = 'static'
  config.metastore = 'memory'
end

# Encrypt sensitive data
user_id = 'user_123'
credit_card = '4111-1111-1111-1111'

encrypted_cc = Asherah.encrypt(user_id, credit_card)
puts "Encrypted: #{encrypted_cc}"

# Decrypt when needed
decrypted_cc = Asherah.decrypt(user_id, encrypted_cc)
puts "Decrypted: #{decrypted_cc}"

# Cleanup
Asherah.shutdown
```

### Handling Multiple Data Types

```ruby
# Encrypt various data types by converting to string
user_data = {
  ssn: '123-45-6789',
  salary: 95000,
  birth_date: Date.new(1990, 5, 15)
}

encrypted_data = {}
user_data.each do |key, value|
  encrypted_data[key] = Asherah.encrypt("user_123", value.to_s)
end

# Decrypt and restore original types
decrypted_data = {}
encrypted_data.each do |key, encrypted_value|
  decrypted_value = Asherah.decrypt("user_123", encrypted_value)
  
  case key
  when :salary
    decrypted_data[key] = decrypted_value.to_i
  when :birth_date
    decrypted_data[key] = Date.parse(decrypted_value)
  else
    decrypted_data[key] = decrypted_value
  end
end
```

## Rails Integration

### Configuration in Rails

```ruby
# config/initializers/asherah.rb
require 'asherah'

Rails.application.config.after_initialize do
  Asherah.configure do |config|
    config.service_name = Rails.application.class.module_parent_name.underscore
    config.product_id = ENV.fetch('PRODUCT_ID', 'my_product')
    
    if Rails.env.production?
      config.kms = 'aws'
      config.metastore = 'rdbms'
      config.connection_string = ENV.fetch('ASHERAH_DB_URL')
      config.preferred_region = ENV.fetch('AWS_REGION', 'us-west-2')
      config.region_map = {
        ENV.fetch('AWS_REGION') => ENV.fetch('KMS_KEY_ARN')
      }
    else
      config.kms = 'static'
      config.metastore = 'memory'
    end
    
    config.enable_session_caching = true
    config.session_cache_max_size = 1000
  end
end

# Ensure cleanup on exit
at_exit { Asherah.shutdown if defined?(Asherah) }
```

### ActiveRecord Model Integration

```ruby
# app/models/concerns/encryptable.rb
module Encryptable
  extend ActiveSupport::Concern

  class_methods do
    def encrypt_field(field_name, partition_key: :id)
      # Define getter
      define_method(field_name) do
        encrypted_value = read_attribute("encrypted_#{field_name}")
        return nil if encrypted_value.nil?
        
        partition = send(partition_key).to_s
        Asherah.decrypt(partition, encrypted_value)
      rescue => e
        Rails.logger.error "Decryption failed for #{field_name}: #{e.message}"
        nil
      end
      
      # Define setter
      define_method("#{field_name}=") do |value|
        if value.nil?
          write_attribute("encrypted_#{field_name}", nil)
        else
          partition = send(partition_key).to_s
          encrypted_value = Asherah.encrypt(partition, value.to_s)
          write_attribute("encrypted_#{field_name}", encrypted_value)
        end
      end
      
      # Define query scope
      scope "with_decrypted_#{field_name}", -> {
        all.map do |record|
          record.define_singleton_method(:decrypted_value) do
            send(field_name)
          end
          record
        end
      }
    end
  end
end

# app/models/user.rb
class User < ApplicationRecord
  include Encryptable
  
  encrypt_field :ssn
  encrypt_field :credit_card
  encrypt_field :api_key, partition_key: :organization_id
  
  # Regular validations work with virtual attributes
  validates :ssn, presence: true, format: { with: /\A\d{3}-\d{2}-\d{4}\z/ }
end

# Usage
user = User.new(ssn: '123-45-6789')
user.save!  # SSN is encrypted before saving

user.ssn  # Decrypted on access
user.encrypted_ssn  # Raw encrypted data
```

### Rails Form Handling

```ruby
# app/controllers/users_controller.rb
class UsersController < ApplicationController
  def create
    @user = User.new(user_params)
    
    if @user.save
      redirect_to @user, notice: 'User created successfully.'
    else
      render :new
    end
  end

  private

  def user_params
    # Virtual attributes work seamlessly
    params.require(:user).permit(:name, :email, :ssn, :credit_card)
  end
end

# app/views/users/_form.html.erb
<%= form_with(model: user) do |form| %>
  <%= form.label :ssn %>
  <%= form.text_field :ssn %>  <!-- Works with encrypted field -->
  
  <%= form.label :credit_card %>
  <%= form.text_field :credit_card %>  <!-- Automatically encrypted -->
<% end %>
```

## Sinatra Integration

```ruby
# app.rb
require 'sinatra'
require 'asherah'
require 'json'

configure do
  Asherah.configure do |config|
    config.service_name = 'sinatra_app'
    config.product_id = 'my_product'
    config.kms = 'static'
    config.metastore = 'memory'
  end
end

helpers do
  def encrypt_params(params, partition_id)
    params.transform_values do |value|
      Asherah.encrypt(partition_id, value.to_s)
    end
  end
  
  def decrypt_params(params, partition_id)
    params.transform_values do |value|
      Asherah.decrypt(partition_id, value)
    end
  end
end

post '/api/secure-data' do
  content_type :json
  
  user_id = request.env['HTTP_X_USER_ID']
  encrypted_data = encrypt_params(JSON.parse(request.body.read), user_id)
  
  # Store encrypted_data in database
  { status: 'success', id: SecureRandom.uuid }.to_json
end

get '/api/secure-data/:id' do
  content_type :json
  
  user_id = request.env['HTTP_X_USER_ID']
  # Fetch encrypted_data from database
  
  decrypted_data = decrypt_params(encrypted_data, user_id)
  decrypted_data.to_json
end
```

## Background Jobs

### Sidekiq Integration

```ruby
# app/workers/sensitive_data_processor.rb
class SensitiveDataProcessor
  include Sidekiq::Worker
  
  def perform(user_id, encrypted_data_json)
    # Decrypt data for processing
    encrypted_data = JSON.parse(encrypted_data_json)
    
    decrypted_data = encrypted_data.transform_values do |encrypted_value|
      Asherah.decrypt(user_id.to_s, encrypted_value)
    end
    
    # Process decrypted data
    process_sensitive_data(decrypted_data)
    
    # Never log decrypted data
    logger.info "Processed data for user #{user_id}"
  rescue => e
    logger.error "Failed to process data for user #{user_id}: #{e.message}"
    raise
  end
  
  private
  
  def process_sensitive_data(data)
    # Business logic here
  end
end

# Enqueue job with encrypted data
user = User.find(123)
encrypted_data = {
  ssn: Asherah.encrypt(user.id.to_s, user.ssn),
  income: Asherah.encrypt(user.id.to_s, user.income.to_s)
}

SensitiveDataProcessor.perform_async(user.id, encrypted_data.to_json)
```

### Delayed Job Integration

```ruby
# app/jobs/encrypt_bulk_data_job.rb
class EncryptBulkDataJob < ApplicationJob
  queue_as :default
  
  def perform(model_class, field_name, batch_size: 1000)
    model = model_class.constantize
    
    model.where("encrypted_#{field_name}" => nil).find_in_batches(batch_size: batch_size) do |batch|
      batch.each do |record|
        next if record.send(field_name).blank?
        
        begin
          # Encrypt using record's ID as partition
          encrypted_value = Asherah.encrypt(
            record.id.to_s,
            record.send(field_name)
          )
          
          record.update_column("encrypted_#{field_name}", encrypted_value)
        rescue => e
          Rails.logger.error "Failed to encrypt #{field_name} for #{model}##{record.id}: #{e.message}"
        end
      end
    end
  end
end

# Usage
EncryptBulkDataJob.perform_later('User', 'ssn')
```

## Multi-Tenant Applications

```ruby
# app/models/concerns/tenant_encryptable.rb
module TenantEncryptable
  extend ActiveSupport::Concern
  
  included do
    def encryption_partition
      # Use tenant ID as partition for data isolation
      "tenant_#{Current.tenant_id}"
    end
  end
  
  class_methods do
    def encrypt_tenant_field(field_name)
      define_method(field_name) do
        encrypted_value = read_attribute("encrypted_#{field_name}")
        return nil if encrypted_value.nil?
        
        Asherah.decrypt(encryption_partition, encrypted_value)
      end
      
      define_method("#{field_name}=") do |value|
        if value.nil?
          write_attribute("encrypted_#{field_name}", nil)
        else
          encrypted_value = Asherah.encrypt(encryption_partition, value.to_s)
          write_attribute("encrypted_#{field_name}", encrypted_value)
        end
      end
    end
  end
end

# app/models/tenant_user.rb
class TenantUser < ApplicationRecord
  include TenantEncryptable
  
  belongs_to :tenant
  
  encrypt_tenant_field :ssn
  encrypt_tenant_field :bank_account
end

# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  around_action :with_current_tenant
  
  private
  
  def with_current_tenant
    Current.tenant_id = session[:tenant_id]
    yield
  ensure
    Current.tenant_id = nil
  end
end
```

## Microservices

### Service A - Encryption Service

```ruby
# Encrypts data for other services
class EncryptionService < Grape::API
  format :json
  
  before do
    authenticate_service!
  end
  
  params do
    requires :partition_id, type: String
    requires :data, type: Hash
  end
  post '/encrypt' do
    encrypted_data = params[:data].transform_values do |value|
      Asherah.encrypt(params[:partition_id], value.to_s)
    end
    
    { encrypted_data: encrypted_data }
  end
  
  params do
    requires :partition_id, type: String
    requires :encrypted_data, type: Hash
  end
  post '/decrypt' do
    decrypted_data = params[:encrypted_data].transform_values do |value|
      Asherah.decrypt(params[:partition_id], value)
    end
    
    { data: decrypted_data }
  rescue => e
    error!({ error: 'Decryption failed' }, 400)
  end
end
```

### Service B - Consumer Service

```ruby
# Uses encryption service
class PaymentProcessor
  include HTTParty
  base_uri ENV['ENCRYPTION_SERVICE_URL']
  
  def self.process_payment(user_id, card_details)
    # Encrypt sensitive data before processing
    response = post('/encrypt',
      body: {
        partition_id: user_id,
        data: card_details
      }.to_json,
      headers: {
        'Content-Type' => 'application/json',
        'Authorization' => "Bearer #{service_token}"
      }
    )
    
    encrypted_data = response['encrypted_data']
    
    # Store or transmit encrypted_data safely
    store_payment_record(user_id, encrypted_data)
  end
  
  private
  
  def self.service_token
    ENV['SERVICE_AUTH_TOKEN']
  end
end
```

## Data Migration

### Encrypting Existing Data

```ruby
# lib/tasks/encrypt_existing_data.rake
namespace :asherah do
  desc "Encrypt existing unencrypted data"
  task encrypt_existing: :environment do
    models_to_encrypt = [
      { model: User, fields: [:ssn, :phone_number] },
      { model: PaymentMethod, fields: [:account_number, :routing_number] }
    ]
    
    models_to_encrypt.each do |config|
      model = config[:model]
      fields = config[:fields]
      
      puts "Encrypting #{model.name} fields: #{fields.join(', ')}"
      
      model.find_in_batches(batch_size: 100) do |batch|
        batch.each do |record|
          fields.each do |field|
            next if record.send("encrypted_#{field}").present?
            next if record.send(field).blank?
            
            begin
              record.send("#{field}=", record.send(field))
              record.save(validate: false)
              print '.'
            rescue => e
              puts "\nFailed to encrypt #{model.name}##{record.id} #{field}: #{e.message}"
            end
          end
        end
      end
      puts "\nCompleted #{model.name}"
    end
  end
  
  desc "Verify encrypted data integrity"
  task verify_encryption: :environment do
    User.find_each do |user|
      begin
        # Try to decrypt each field
        user.ssn
        user.phone_number
      rescue => e
        puts "Decryption failed for User##{user.id}: #{e.message}"
      end
    end
  end
end
```

## Testing Strategies

### RSpec Examples

```ruby
# spec/support/asherah_helpers.rb
module AsherahHelpers
  def with_asherah_encryption
    before(:all) do
      Asherah.configure do |config|
        config.service_name = 'rspec_test'
        config.product_id = 'test'
        config.kms = 'test-debug-static'
        config.metastore = 'test-debug-memory'
      end
    end
    
    after(:all) do
      Asherah.shutdown
    end
  end
end

RSpec.configure do |config|
  config.extend AsherahHelpers
end

# spec/models/user_spec.rb
RSpec.describe User, type: :model do
  with_asherah_encryption
  
  describe 'encrypted fields' do
    let(:user) { User.new(ssn: '123-45-6789') }
    
    it 'encrypts SSN on save' do
      user.save!
      expect(user.encrypted_ssn).to be_present
      expect(user.encrypted_ssn).not_to eq('123-45-6789')
    end
    
    it 'decrypts SSN on access' do
      user.save!
      reloaded_user = User.find(user.id)
      expect(reloaded_user.ssn).to eq('123-45-6789')
    end
    
    it 'handles nil values' do
      user.ssn = nil
      user.save!
      expect(user.encrypted_ssn).to be_nil
      expect(user.ssn).to be_nil
    end
  end
end

# spec/services/encryption_service_spec.rb
RSpec.describe EncryptionService do
  with_asherah_encryption
  
  describe '#encrypt_user_data' do
    let(:service) { described_class.new }
    let(:user_data) {
      {
        name: 'John Doe',
        ssn: '123-45-6789',
        salary: 75000
      }
    }
    
    it 'encrypts sensitive fields only' do
      result = service.encrypt_user_data('user_123', user_data)
      
      expect(result[:name]).to eq('John Doe')  # Not encrypted
      expect(result[:ssn]).not_to eq('123-45-6789')  # Encrypted
      expect(result[:salary]).not_to eq('75000')  # Encrypted
    end
    
    it 'can decrypt encrypted data' do
      encrypted = service.encrypt_user_data('user_123', user_data)
      decrypted = service.decrypt_user_data('user_123', encrypted)
      
      expect(decrypted).to eq(user_data.transform_values(&:to_s))
    end
  end
end
```

### Test Factories

```ruby
# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    email { Faker::Internet.email }
    
    trait :with_encrypted_data do
      ssn { '123-45-6789' }
      credit_card { '4111111111111111' }
      
      after(:create) do |user|
        # Force encryption by triggering setter
        user.update(
          ssn: user.ssn,
          credit_card: user.credit_card
        )
      end
    end
  end
end

# Usage in tests
let(:user) { create(:user, :with_encrypted_data) }
```