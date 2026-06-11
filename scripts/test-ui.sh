#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=compose-env.sh
source "$(dirname "$0")/compose-env.sh"

compose run --rm tester node node_modules/@playwright/test/cli.js test
