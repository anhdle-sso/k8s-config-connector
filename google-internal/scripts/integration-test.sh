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

function jreport {
  if [[ -z "${ARTIFACTS}" ]]; then
    echo "${ARTIFACTS} env var is missing, JUnit report will not be generated"
    return
  fi

  cp test_*.txt ${ARTIFACTS}/

  cat test_int_log1.txt | ${REPO_ROOT}/hack/convert-to-junit-report > ${ARTIFACTS}/junit_int_report1.xml
  cat test_int_log2.txt | ${REPO_ROOT}/hack/convert-to-junit-report > ${ARTIFACTS}/junit_int_report2.xml
  cat test_int_log3.txt | ${REPO_ROOT}/hack/convert-to-junit-report > ${ARTIFACTS}/junit_int_report3.xml
  cat test_int_log4.txt | ${REPO_ROOT}/hack/convert-to-junit-report > ${ARTIFACTS}/junit_int_report4.xml
  cat test_int_log5.txt | ${REPO_ROOT}/hack/convert-to-junit-report > ${ARTIFACTS}/junit_int_report5.xml
  cat test_int_log6.txt | ${REPO_ROOT}/hack/convert-to-junit-report > ${ARTIFACTS}/junit_int_report6.xml
  cat test_int_log7.txt | ${REPO_ROOT}/hack/convert-to-junit-report > ${ARTIFACTS}/junit_int_report7.xml
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

# Temporarily disabled tests are kept in pkg/test/constants/constants.go

# Regex used to match periodic tests to be skipped during the main test run.
# Note: cloudidentitygroup and cloudidentitymembership are tested separately (in
# cloudidentity-integration-test.sh) because they need to run as a pre-created & pre-enabled
# service account, which includes needing to generate a key for that service
# account (SA can only have at most 10 keys at any time).
PERIODIC_CRUD_TESTS_REGEX="cloudidentitygroup|cloudidentitymembership|computeinterconnectattachment|computefirewallpolicy|computefirewallpolicyassociation|computefirewallpolicyrule|iamaccessboundarypolicy|iamworkforcepool|oidcworkforcepoolprovider|samlworkforcepoolprovider"

# Regex used to match test cases for auto-generated resources. Their test names
# should all end with 'autogen'.
AUTOGEN_TESTS_REGEX="autogen$"

# Regex used to match tests to be skipped during the main test run.
SKIP_CRUD_TESTS_ON_MAIN_RUN_REGEX="${PERIODIC_CRUD_TESTS_REGEX}|${LONG_RUNNING_CRUD_TESTS_REGEX}|${AUTOGEN_TESTS_REGEX}|${FLAKY_TESTS_REGEX}"

# Regex used to match IAM tests to be skipped during the main test run.
# TODO(b/220357089): re-enable eventfunction test in IAM test suite.
# TODO(b/240727419): Remove iamworkforcepool from the regex below to enable IAM tests.
SKIP_IAM_TESTS_ON_MAIN_RUN_REGEX="eventfunction|iamworkforcepool"

# Divide the integration test suite into several parts and run them in parallel separately
# (i.e. in their own processes and with their own GCP projects). This is done
# to improve test velocity and to prevent quota issues.

# Long-running (10m+) Beta CRUD tests
${REPO_ROOT}/google-internal/scripts/run-command-new-env.sh \
  --command "${REPO_ROOT}/google-internal/scripts/run-tests-fresh-environment.sh \
    --target-directory '${CRUD_TEST_PACKAGE}/...' \
    --run-tests '${LONG_RUNNING_CRUD_TESTS_REGEX}' \
    --skip-tests '${FLAKY_TESTS_REGEX}'\
    --run-tests-version beta \
  " 2>&1 | tee test_int_log1.txt &
PROCESS1=$!

# Regular Beta CRUD tests
sleep 120 # Sleep for a bit to reduce conflicts (e.g. IAM permissions) during project set-up.
${REPO_ROOT}/google-internal/scripts/run-command-new-env.sh \
  --command "${REPO_ROOT}/google-internal/scripts/run-tests-fresh-environment.sh \
    --target-directory '${CRUD_TEST_PACKAGE}/...' \
    --skip-tests '${SKIP_CRUD_TESTS_ON_MAIN_RUN_REGEX}'\
    --run-tests-version beta \
  " 2>&1 | tee test_int_log2.txt &
PROCESS2=$!

# Singleton tests (due to quota and instance count limitation at org/project level)
sleep 120 # Sleep for a bit to reduce conflicts (e.g. IAM permissions) during project set-up.
SINGLETON_TEST_COMMAND="${REPO_ROOT}/google-internal/scripts/run-tests-fresh-environment.sh \
--target-directory ./pkg/controller/dynamic \
--run-tests 'computeinterconnectattachment|computefirewallpolicy|computefirewallpolicyassociation|computefirewallpolicyrule' \
--skip-tests '${FLAKY_TESTS_REGEX}'"
${REPO_ROOT}/google-internal/scripts/run-command-new-env.sh --command "${SINGLETON_TEST_COMMAND}" 2>&1 | tee test_int_log3.txt
PROCESS3=$!

# Special periodic CRUD test case: CloudIdentity
sleep 120 # Sleep for a bit to reduce conflicts (e.g. IAM permissions) during project set-up.
${REPO_ROOT}/google-internal/scripts/cloudidentity-integration-test.sh 2>&1 | tee test_int_log4.txt
PROCESS4=$!

# Special period CRUD test case: IAMWorkforcePool
sleep 120 # Sleep for a bit to reduce conflicts (e.g. IAM permissions) during project set-up.
${REPO_ROOT}/google-internal/scripts/iam-integration-test.sh 2>&1 | tee test_int_log5.txt
PROCESS5=$!

# IAM tests
sleep 120 # Sleep for a bit to reduce conflicts (e.g. IAM permissions) during project set-up.
${REPO_ROOT}/google-internal/scripts/run-command-new-env.sh \
  --command "${REPO_ROOT}/google-internal/scripts/run-tests-fresh-environment.sh \
    --target-directory '${IAM_TEST_PACKAGE}' \
    --skip-tests '${SKIP_IAM_TESTS_ON_MAIN_RUN_REGEX}|${IAM_FAILED_TESTS_REGEX}' \
    --go-test-skip '${IAM_FAILED_TEST_FUNCS}'\
  " 2>&1 | tee test_int_log6.txt &
PROCESS6=$!

# All other tests
sleep 120 # Sleep for a bit to reduce conflicts (e.g. IAM permissions) during project set-up.
${REPO_ROOT}/google-internal/scripts/run-command-new-env.sh \
  --command "${REPO_ROOT}/google-internal/scripts/run-tests-fresh-environment.sh \
    --target-directory '${OTHER_TEST_PACKAGES}' \
    --go-test-skip '${OTHER_FAILED_TEST_FUNCS}'\
  " 2>&1 | tee test_int_log7.txt &
PROCESS7=$!

wait ${PROCESS1}
wait ${PROCESS2}
wait ${PROCESS3}
wait ${PROCESS4}
wait ${PROCESS5}
wait ${PROCESS6}
wait ${PROCESS7}
