#!/bin/bash
# Copyright 2025 Google LLC
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

function jreport {
  if [[ -z "${ARTIFACTS}" ]]; then
    echo "${ARTIFACTS} env var is missing, JUnit report will not be generated"
    return
  fi

  cp test_*.txt ${ARTIFACTS}/

  cat test_int_log1.txt | ${REPO_ROOT}/hack/convert-to-junit-report > ${ARTIFACTS}/junit_int_report1.xml
}

trap jreport EXIT

set -o nounset
set -o pipefail
# Integration test runs as periodic prow jobs, we want to finish the full run and
# avoid early exit to collect full test log from all child processes for JUnit report.
set +e

REPO_ROOT="$(git rev-parse --show-toplevel)"
source "${REPO_ROOT}/google-internal/scripts/shared-vars.sh"
cd ${REPO_ROOT}

IAM_TEST_PACKAGE="github.com/GoogleCloudPlatform/k8s-config-connector/pkg/controller/iam/iamclient"

# Regex used to match IAM tests to be skipped during the main test run.
# TODO(b/220357089): re-enable eventfunction test in IAM test suite.
# TODO(b/240727419): Remove iamworkforcepool from the regex below to enable IAM tests.
SKIP_IAM_TESTS_ON_MAIN_RUN_REGEX="eventfunction|iamworkforcepool"

# IAM tests
${REPO_ROOT}/google-internal/scripts/run-command-new-env.sh \
  --command "${REPO_ROOT}/google-internal/scripts/run-tests-fresh-environment-in-series.sh \
    --target-directory '${IAM_TEST_PACKAGE}' \
    --skip-tests '${SKIP_IAM_TESTS_ON_MAIN_RUN_REGEX}|${IAM_FAILED_TESTS_REGEX}' \
    --go-test-skip '${IAM_FAILED_TEST_FUNCS}'\
  " 2>&1 | tee test_int_log1.txt &
PROCESS1=$!

wait ${PROCESS1}
