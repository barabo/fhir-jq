#!/bin/bash
#
# Runs the jq module tests.
#

set -e
set -o pipefail
set -u


# This might be too simplistic, if there are some tests that need to be run
# before others, but it's a start.
find "$( dirname "${0}" )" -type f -name '*.test' \
  | xargs -n1 fhir-jq --run-tests
