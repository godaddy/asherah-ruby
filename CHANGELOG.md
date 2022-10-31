## [Unreleased]

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
