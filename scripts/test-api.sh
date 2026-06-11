#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=compose-env.sh
source "$(dirname "$0")/compose-env.sh"

compose run --rm tester bun test blackbox/api
