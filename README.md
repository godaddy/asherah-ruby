# Asherah

Asherah is a Ruby wrapper around [Asherah Go](https://github.com/godaddy/asherah) application-layer encryption SDK that provides advanced encryption features and defense in depth against compromise. It uses a technique known as "envelope encryption" and supports cloud-agnostic data storage and key management.

Check out the following documentation to get more familiar with its concepts:

- [Design and Architecture](https://github.com/godaddy/asherah/blob/master/docs/DesignAndArchitecture.md)
- [Key Caching](https://github.com/godaddy/asherah/blob/master/docs/KeyCaching.md)
- [Key Management Service](https://github.com/godaddy/asherah/blob/master/docs/KeyManagementService.md)
- [Metastore](https://github.com/godaddy/asherah/blob/master/docs/Metastore.md)
- [System Requirements](https://github.com/godaddy/asherah/blob/master/docs/SystemRequirements.md)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'asherah'
```

```bash
bundle install
```

Or install it yourself as:

```bash
gem install asherah
```

## Usage

Configure Asherah:

```ruby
Asherah.configure do |config|
  config.kms = 'static'
  config.metastore = 'memory'
  config.service_name = 'service'
  config.product_id = 'product'
end
```

Encrypt some data for a `partition_id`

```ruby
partition_id = 'user_1'
data = 'Some PII data'
data_row_record_json = Asherah.encrypt(partition_id, data)
puts data_row_record_json
```

Decrypt `data_row_record_json`

```ruby
decrypted_data = Asherah.decrypt(partition_id, data_row_record_json)
puts decrypted_data
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/godaddy/asherah-ruby.

## Releasing new gem version

```
# Create and push a version tag
git tag -a v$(rake version) -m "Version $(rake version)"
git push origin v$(rake version)

# Create a release in Github to trigger .github/workflows/publish.yml workflow
echo "Version $(rake version)"
```

## License

The gem is available as open source under the terms of the [MIT License](LICENSE.txt).
