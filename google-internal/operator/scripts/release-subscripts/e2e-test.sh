#!/bin/bash
# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


# This script runs the operator e2e tests for a given operator release
# candidate. It can only be used to test operator release candidates that have
# already been uploaded to the staging bucket (gs://kcc-operator-internal).
#
# Usage:
#   e2e-test.sh SHORT_SHA
#
#   SHORT_SHA: the operator release candidate to run the e2e tests for (i.e.
#   which operator release bundle in gs://kcc-operator-internal to pull down
#   for testing).

set -o errexit
set -o nounset
set -o pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
source "${REPO_ROOT}/google-internal/scripts/shared-vars.sh"

if [ "$#" -ne 1 ]; then
  echo "Error: Incorrect number of arguments: $# (required: 1)."
  exit 1
fi

OPERATOR_SRC_ROOT="${REPO_ROOT}/operator"
SHORT_SHA="${1}"
UNIQUE_ID=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 12 | head -n 1) || true # trailing 'true' ensures that script doesn't exit due to non-zero exit code

TEST_ORG_ID=${ORGANIZATION_ID} \
  TEST_BILLING_ACCOUNT_ID=${BILLING_ACCOUNT_ID} \
  go test -v ${OPERATOR_SRC_ROOT}/tests/e2e/e2e_test.go --version ${SHORT_SHA} --project-id "cnrm-test-${UNIQUE_ID}" --timeout 60m
