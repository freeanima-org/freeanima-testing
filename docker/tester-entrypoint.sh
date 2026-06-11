#!/usr/bin/env sh
set -e

cd /workspace
bun install
exec "$@"
