#!/bin/bash

set -xeu

ROOT_DIR=$(pwd)
ASHERAH_GO_DIR=$(pwd)/tmp/asherah
ASHERAH_GO_TEST_DIR=$(pwd)/tmp/asherah/tests/cross-language/go

# Clean tmp dir
rm -rf $ASHERAH_GO_DIR

# Clone Asherah repo
mkdir -p $ASHERAH_GO_DIR
cd $ASHERAH_GO_DIR
git clone https://github.com/godaddy/asherah.git .

# Install Go packages
cd $ASHERAH_GO_TEST_DIR
# Fix invalid toolchain directive
sed -i.bak '/^toolchain/d' go.mod
go build ./...
go mod edit -replace github.com/godaddy/asherah/go/appencryption=../../../go/appencryption
go mod tidy
go install github.com/cucumber/godog/cmd/godog@latest

# Encrypt with Go
cd $ASHERAH_GO_TEST_DIR
godog run "$ROOT_DIR/features/encrypt.feature"

# Encrypt with Ruby
cd $ROOT_DIR
bundle exec cucumber "$ROOT_DIR/features/encrypt.feature"

# Decrypt all with Ruby
cd $ROOT_DIR
bundle exec cucumber "$ROOT_DIR/features/decrypt.feature"

# Decrypt all with Go
cd $ASHERAH_GO_TEST_DIR
godog run "$ROOT_DIR/features/decrypt.feature"
