# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Setup
- `bin/setup` - Install dependencies and setup development environment
- `bundle install` - Install Ruby gem dependencies

### Testing  
- `rake spec` - Run RSpec test suite
- `COVERAGE=true bundle exec rake spec` - Run tests with coverage reporting
- `bundle exec cucumber` - Run Cucumber feature tests
- `ruby spec/smoke_test.rb` - Run smoke tests (without bundle exec to test installed gem)

### Code Quality
- `bundle exec rubocop` - Run Ruby linter
- `rake` - Run default task (specs + rubocop)

### Build and Release
- `rake build` - Build the gem
- `rake install` - Install gem locally  
- `rake download` - Download native binary for current platform
- `rake version` - Print current version
- `rake native:build:PLATFORM` - Build platform-specific gem (e.g., x86_64-linux, aarch64-linux)

## Architecture Overview

This is a Ruby FFI wrapper around the Go version of Asherah application-layer encryption SDK. The gem provides envelope encryption with cloud-agnostic data storage and key management.

### Core Components

**Main Module (`lib/asherah.rb`)**
- Primary interface exposing `encrypt()` and `decrypt()` methods
- Uses Cobhan FFI to interface with Go shared library (`libasherah`)
- Manages configuration through `Config` class
- Handles memory buffer allocation/deallocation for C interop

**Configuration (`lib/asherah/config.rb`)**
- Supports multiple KMS backends: static, aws, test-debug-static
- Supports multiple metastores: rdbms, dynamodb, memory, test-debug-memory
- Validates required configuration based on chosen backends
- Maps Ruby config attributes to Go JSON format

**Native Binary Management (`ext/asherah/`)**
- `extconf.rb` - Ruby extension configuration that triggers binary download
- `native_file.rb` - Downloads platform-specific Go shared library from GitHub releases
- `checksums.yml` - SHA256 checksums for binary verification
- Downloaded binaries are placed in `lib/asherah/native/`

### Key Workflows

**Initialization**
1. Configure Asherah with KMS and metastore settings
2. Native binary is automatically downloaded during gem installation
3. Go library is loaded via FFI and initialized with JSON config

**Encryption/Decryption**
- Data is encrypted for a specific `partition_id` 
- Returns/expects DataRowRecord JSON containing encrypted data and key metadata
- Uses envelope encryption with intermediate keys cached based on configuration

**Testing Strategy**
- Unit tests with RSpec in `spec/`
- Cucumber integration tests in `features/`
- Cross-language compatibility tests with Go implementation
- Smoke tests validate installed gem functionality
- CI tests multiple Ruby versions (2.7-3.2) and platforms (Linux/macOS, x64/ARM64)

## Platform Support

Supports Linux and macOS on x86_64 and aarch64 architectures. Native binaries are fetched from [asherah-cobhan releases](https://github.com/godaddy/asherah-cobhan/releases).