#!/bin/bash
# Copyright 2024 Google LLC
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

  cat test_int_flaky_log1.txt | ${REPO_ROOT}/hack/convert-to-junit-report > ${ARTIFACTS}/junit_int_flaky_report1.xml
  cat test_int_flaky_log2.txt | ${REPO_ROOT}/hack/convert-to-junit-report > ${ARTIFACTS}/junit_int_flaky_report2.xml
  cat test_int_flaky_log3.txt | ${REPO_ROOT}/hack/convert-to-junit-report > ${ARTIFACTS}/junit_int_flaky_report3.xml
  cat test_int_flaky_log4.txt | ${REPO_ROOT}/hack/convert-to-junit-report > ${ARTIFACTS}/junit_int_flaky_report4.xml
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

CRUD_TEST_PACKAGE="github.com/GoogleCloudPlatform/k8s-config-connector/pkg/controller/dynamic"
IAM_TEST_PACKAGE="github.com/GoogleCloudPlatform/k8s-config-connector/pkg/controller/iam/iamclient"
OTHER_TEST_PACKAGES=$(go list ./pkg/... | grep -v ${CRUD_TEST_PACKAGE} | grep -v ${IAM_TEST_PACKAGE})

# Flaky Beta CRUD tests.
${REPO_ROOT}/google-internal/scripts/run-command-new-env.sh \
  --command "${REPO_ROOT}/google-internal/scripts/run-tests-fresh-environment.sh \
    --target-directory '${CRUD_TEST_PACKAGE}/...' \
    --run-tests '${FLAKY_TESTS_REGEX}'\
    --run-tests-version beta \
  " 2>&1 | tee test_int_flaky_log1.txt &
PROCESS1=$!

# Flaky IAM tests.
sleep 120 # Sleep for a bit to reduce conflicts (e.g. IAM permissions) during project set-up.
${REPO_ROOT}/google-internal/scripts/run-command-new-env.sh \
  --command "${REPO_ROOT}/google-internal/scripts/run-tests-fresh-environment.sh \
    --target-directory '${IAM_TEST_PACKAGE}' \
    --run-tests '${IAM_FAILED_TESTS_REGEX}' \
    --go-test-skip '${IAM_FAILED_TEST_FUNCS}'\
  " 2>&1 | tee test_int_flaky_log2.txt &
PROCESS2=$!
sleep 120 # Sleep for a bit to reduce conflicts (e.g. IAM permissions) during project set-up.
${REPO_ROOT}/google-internal/scripts/run-command-new-env.sh \
  --command "${REPO_ROOT}/google-internal/scripts/run-tests-fresh-environment.sh \
    --target-directory '${IAM_TEST_PACKAGE}' \
    --go-test-run '${IAM_FAILED_TEST_FUNCS}'\
  " 2>&1 | tee test_int_flaky_log3.txt &
PROCESS3=$!

# All other flaky tests.
sleep 120 # Sleep for a bit to reduce conflicts (e.g. IAM permissions) during project set-up.
${REPO_ROOT}/google-internal/scripts/run-command-new-env.sh \
  --command "${REPO_ROOT}/google-internal/scripts/run-tests-fresh-environment.sh \
    --target-directory '${OTHER_TEST_PACKAGES}' \
    --go-test-run '${OTHER_FAILED_TEST_FUNCS}'\
  " 2>&1 | tee test_int_flaky_log4.txt &
PROCESS4=$!

# Using wait command as we may add more test commands in parallel in the future.
wait ${PROCESS1}
wait ${PROCESS2}
wait ${PROCESS3}
wait ${PROCESS4}
