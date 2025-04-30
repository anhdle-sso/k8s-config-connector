#!/usr/bin/env bash
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

set -o nounset
set -o pipefail
# Integration test runs as periodic prow jobs, we want to finish the full run and
# avoid early exit to collect full test log from all child processes for JUnit report.
set +e

REPO_ROOT="$(git rev-parse --show-toplevel)"
source "${REPO_ROOT}/google-internal/scripts/shared-vars.sh"

cd ${REPO_ROOT}

source ${REPO_ROOT}/scripts/fetch_ext_bins.sh && \
	fetch_tools && \
	setup_envs

${REPO_ROOT}/scripts/validate-prereqs.sh

function jreport {
  if [[ -z "${ARTIFACTS}" ]]; then
    echo "${ARTIFACTS} env var is missing, JUnit report will not be generated"
    return
  fi

  cp test_*.txt ${ARTIFACTS}/

  cat test_int_log1.txt | ${REPO_ROOT}/hack/convert-to-junit-report > ${ARTIFACTS}/junit_int_report1.xml
  cat test_int_log2.txt | ${REPO_ROOT}/hack/convert-to-junit-report > ${ARTIFACTS}/junit_int_report2.xml
  cat test_int_log3.txt | ${REPO_ROOT}/hack/convert-to-junit-report > ${ARTIFACTS}/junit_int_report3.xml
}

trap jreport EXIT

echo "Activating service-account in gcloud..."
gcloud auth activate-service-account --key-file=${GOOGLE_APPLICATION_CREDENTIALS}

CRUD_TEST_PACKAGE="github.com/GoogleCloudPlatform/k8s-config-connector/pkg/controller/dynamic"
TEST_GROUP_REGEX="alloydb"

# Split out the long-running test cases into small batches that can be finished
# in two hours when running in series.
# basicsecondaryalloydbinstance test takes about 2200s to finish
# readalloydbinstance test takes about 2400s to finish
# fullalloydbinstance test takes about 3100s to finish
# basicalloydbinstance test takes about 1900s to finish
LONG_RUNNING_CRUD_TESTS_REGEX_1="basicsecondaryalloydbinstance|readalloydbinstance"
LONG_RUNNING_CRUD_TESTS_REGEX_2="fullalloydbinstance|basicalloydbinstance"

# Divide the integration test suite into several parts and run them in parallel separately
# (i.e. in their own processes and with their own GCP projects). This is done
# to improve test velocity and to prevent quota issues.

${REPO_ROOT}/google-internal/scripts/run-command-new-env-in-series.sh \
  --command "${REPO_ROOT}/google-internal/scripts/run-tests-fresh-environment-in-series.sh \
    --target-directory '${CRUD_TEST_PACKAGE}/...' \
    --run-tests '${LONG_RUNNING_CRUD_TESTS_REGEX_1}' \
    --skip-tests '${FLAKY_TESTS_REGEX}'\
  " 2>&1 | tee test_int_log1.txt &
PROCESS1=$!

sleep 120 # Sleep for a bit to reduce conflicts (e.g. IAM permissions) during project set-up.
${REPO_ROOT}/google-internal/scripts/run-command-new-env-in-series.sh \
  --command "${REPO_ROOT}/google-internal/scripts/run-tests-fresh-environment-in-series.sh \
    --target-directory '${CRUD_TEST_PACKAGE}/...' \
    --run-tests '${LONG_RUNNING_CRUD_TESTS_REGEX_2}' \
    --skip-tests '${FLAKY_TESTS_REGEX}'\
  " 2>&1 | tee test_int_log2.txt &
PROCESS2=$!

# It took more than 2 hours to finish running the rest of the AlloyDB tests in
# series so making it running 2 tests in parallel to accelerate.
# We want to minimize the parallelization as much as possible to avoid flakiness
# caused by potential conflict or quota issues.
sleep 120 # Sleep for a bit to reduce conflicts (e.g. IAM permissions) during project set-up.
${REPO_ROOT}/google-internal/scripts/run-command-new-env-in-series.sh \
  --command "${REPO_ROOT}/google-internal/scripts/run-tests-fresh-environment-in-series.sh \
    --target-directory '${CRUD_TEST_PACKAGE}/...' \
    --run-tests '${TEST_GROUP_REGEX}' \
    --skip-tests '${FLAKY_TESTS_REGEX}|${LONG_RUNNING_CRUD_TESTS_REGEX_1}|${LONG_RUNNING_CRUD_TESTS_REGEX_2}'\
    --parallel 2 \
  " 2>&1 | tee test_int_log3.txt &
PROCESS3=$!

wait ${PROCESS1}
wait ${PROCESS2}
wait ${PROCESS3}
