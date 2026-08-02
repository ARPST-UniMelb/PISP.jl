#!/usr/bin/env bash
set -euo pipefail

# Remove stale coverage data.
find src -type f -name '*.cov' -delete
find test -type f -name '*.cov' -delete
find docs -type f -name '*.cov' -delete
