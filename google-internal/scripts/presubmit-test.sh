#!/usr/bin/env bash
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

  cat test_pre_log1.txt | ${REPO_ROOT}/hack/convert-to-junit-report > ${ARTIFACTS}/junit_pre_report1.xml
  cat test_pre_log2.txt | ${REPO_ROOT}/hack/convert-to-junit-report > ${ARTIFACTS}/junit_pre_report2.xml
}

trap jreport EXIT

set -o errexit
set -o nounset
set -o pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
source "${REPO_ROOT}/google-internal/scripts/shared-vars.sh"
cd ${REPO_ROOT}

CRUD_TEST_PACKAGE="github.com/GoogleCloudPlatform/k8s-config-connector/pkg/controller/dynamic"
IAM_TEST_PACKAGE="github.com/GoogleCloudPlatform/k8s-config-connector/pkg/controller/iam/iamclient"
CLI_INT_TEST_PACKAGE="github.com/GoogleCloudPlatform/k8s-config-connector/pkg/cli/gcpclient"
OTHER_TEST_PACKAGES=$(go list ./pkg/... | grep -v ${CRUD_TEST_PACKAGE} | grep -v ${IAM_TEST_PACKAGE} | grep -v ${CLI_INT_TEST_PACKAGE})
TESTS_TO_RUN=$(go run ./scripts/presubmit-lite/main.go)

# Only runs presubmit-lite integration tests as listed in pkg/test/constants/presubmitconstants.go
${REPO_ROOT}/google-internal/scripts/run-command-new-env.sh \
  --command "${REPO_ROOT}/google-internal/scripts/run-tests-fresh-environment.sh \
    --target-directory '${CRUD_TEST_PACKAGE}'\
    --run-tests '${TESTS_TO_RUN}'\
  " | tee test_pre_log1.txt &
PROCESS1=$!

# All other tests
sleep 120 # Sleep for a bit to reduce conflicts (e.g. IAM permissions) during project set-up.
${REPO_ROOT}/google-internal/scripts/run-command-new-env.sh \
  --command "${REPO_ROOT}/google-internal/scripts/run-tests-fresh-environment.sh \
    --target-directory '${OTHER_TEST_PACKAGES}'\
  " | tee test_pre_log2.txt &
PROCESS2=$!

wait ${PROCESS1}
wait ${PROCESS2}
