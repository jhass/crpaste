# crpaste

A simplistic, command line focused pastebin.

## Installation

```sh
# Build assets
corepack install
pnpm install
pnpm run build

# Build backend
shards
crystal build --release src/crpaste.cr

# Prepare database
createdb crpaste
psql crpaste < schema.sql

# Run backend
# Default port: 8000 Change by setting PORT
# Default database: crpaste Change by setting DB
./crpaste
```

## Usage

See [usage](src/usage.md).
