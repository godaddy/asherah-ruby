## [Unreleased]

## [0.5.3] - 2025-03-19

- Upgrade to use asherah-cobhan v0.4.35

## [0.5.2] - 2024-01-15

- Upgrade to use asherah-cobhan v0.4.32

## [0.5.1] - 2023-10-25

- Add `sql_metastore_db_type` config option to support PostgresSQL adapter for Asherah
- Upgrade to use asherah-cobhan v0.4.31

## [0.5.0] - 2023-10-16

- Upgrade to use asherah-cobhan v0.4.30
- Expose `test-debug-static` kms type and `test-debug-memory` metastore type to skip warnings in tests
- Check initialized flag on setup/shutdown and raise appropriate errors

## [0.4.10] - 2023-08-10

- Upgrade to use asherah-cobhan v0.4.25

## [0.4.9] - 2023-07-05

- Upgrade to use asherah-cobhan v0.4.24

## [0.4.8] - 2023-06-06

- Upgrade to use asherah-cobhan v0.4.23

## [0.4.7] - 2023-04-20

- Upgrade to use asherah-cobhan v0.4.22
- Change detault ruby version to 3.2.2

## [0.4.6] - 2023-03-17

- Upgrade to use asherah-cobhan v0.4.20
- Change detault ruby version to 3.2
- Add ruby 3.2 to build matrix
- Remove ruby 2.5 and 2.6 from build matrix

## [0.4.5] - 2022-10-31

- Upgrade to use asherah-cobhan v0.4.18

## [0.4.4] - 2022-09-14

- Upgrade to use asherah-cobhan v0.4.17

## [0.4.3] - 2022-08-31

- Upgrade to use asherah-cobhan v0.4.16

## [0.4.2] - 2022-07-25

- Upgrade to use asherah-cobhan v0.4.15
- Add `set_env` method to set environment variables for Asherah

## [0.4.1] - 2022-03-25

- Build and release platform gems

## [0.4.0] - 2022-03-25

- Download native file during gem install and verify checksum
- Upgrade to use asherah-cobhan v0.4.11

## [0.3.0] - 2022-03-22

- Free up cobhan buffers after encrypt/decrypt to prevent growing heap memory
- Use local `estimate_buffer` calculation instead of FFI call
- Upgrade to use asherah-cobhan v0.4.3

## [0.2.0] - 2022-03-21

- Implement versioning for asherah-cobhan binaries
- Upgrade to use asherah-cobhan v0.3.1
- Add BadConfig error and expose error codes
- Remove DRR methods and use JSON exclusively
- Cross language testing using Asherah Go

## [0.1.0] - 2022-03-14

- First official release

## [0.1.0.beta2] - 2022-03-14

- Add smoke tests for native gems
- Change to use `SetupJson` instead of `Setup`
- Update config options to make them consistent with Asherah Go
- Add `shutdown`
- Add `encrypt_to_json` and `decrypt_from_json`
- Add coverage report

## [0.1.0.beta1] - 2022-03-07

- Initial proof of concept
