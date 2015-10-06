# crpaste

A simplistic, command line focused pastebin.

## Installation

```sh
# Build assets
gem install sass
npm install
bower install
BASE_URL="http://p.example.org" grunt

# Build backend
shards
crystal build --release src/crpaste.cr

# Prepare database
createdb crpaste
psql crpaste < schema.sql

# Run backend
# Default port: 8000 Change by setting PORT
# Default database: crpaste Change by setting DB
BASE_URL="http://p.example.org" ./crpaste
```

## Usage

See {src/crpaste.md}.
