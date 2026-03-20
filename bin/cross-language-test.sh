#!/bin/bash

set -xeu

ROOT_DIR=$(pwd)
ASHERAH_GO_DIR=$(pwd)/tmp/asherah
ASHERAH_GO_TEST_DIR=$(pwd)/tmp/asherah/tests/cross-language/go

# Set database environment variables
export TEST_DB_NAME=${TEST_DB_NAME:-testdb}
export TEST_DB_USER=${TEST_DB_USER:-root}
export TEST_DB_PASSWORD=${TEST_DB_PASSWORD:-}
export TEST_DB_HOSTNAME=${TEST_DB_HOSTNAME:-127.0.0.1}
export TEST_DB_PORT=${TEST_DB_PORT:-3306}

# Set Asherah environment variables
export ASHERAH_SERVICE_NAME=${ASHERAH_SERVICE_NAME:-service}
export ASHERAH_PRODUCT_NAME=${ASHERAH_PRODUCT_NAME:-product}
export ASHERAH_KMS_MODE=${ASHERAH_KMS_MODE:-static}

# Initialize database and table
echo "Initializing database..."
MYSQL_CMD="mysql -h $TEST_DB_HOSTNAME -P$TEST_DB_PORT -u $TEST_DB_USER"
if [ -n "$TEST_DB_PASSWORD" ]; then
  MYSQL_CMD="$MYSQL_CMD -p$TEST_DB_PASSWORD"
fi

# Create database if it doesn't exist
$MYSQL_CMD -e "CREATE DATABASE IF NOT EXISTS $TEST_DB_NAME;" 2>/dev/null || {
  echo "Warning: Could not create database. It may already exist or you may not have permissions."
}

# Create encryption_key table if it doesn't exist
$MYSQL_CMD $TEST_DB_NAME <<'SQL' 2>/dev/null || echo "Warning: Could not create table. It may already exist or you may not have permissions."
CREATE TABLE IF NOT EXISTS encryption_key (
  id VARCHAR(255) NOT NULL,
  created TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  key_record TEXT NOT NULL,
  PRIMARY KEY (id, created),
  INDEX (created)
);
SQL

echo "Database initialization complete."

# Clean tmp dir
rm -rf $ASHERAH_GO_DIR

# Clone Asherah repo
mkdir -p $ASHERAH_GO_DIR
cd $ASHERAH_GO_DIR
git clone https://github.com/godaddy/asherah.git .

# Install Go packages
cd $ASHERAH_GO_TEST_DIR
go build ./...
go mod edit -replace github.com/godaddy/asherah/go/appencryption=../../../go/appencryption
go mod tidy

# Encrypt with Go
cd $ASHERAH_GO_TEST_DIR
go run github.com/cucumber/godog/cmd/godog@latest run "$ROOT_DIR/features/encrypt.feature"

# Encrypt with Ruby
cd $ROOT_DIR
bundle exec cucumber "$ROOT_DIR/features/encrypt.feature"

# Decrypt all with Ruby
cd $ROOT_DIR
bundle exec cucumber "$ROOT_DIR/features/decrypt.feature"

# Decrypt all with Go
cd $ASHERAH_GO_TEST_DIR
go run github.com/cucumber/godog/cmd/godog@latest run "$ROOT_DIR/features/decrypt.feature"
