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

set -o nounset
set -o pipefail

RUN_TESTS_REGEX=""
GO_TEST_RUN_REGEX=""
SKIP_TESTS_REGEX=""
GO_TEST_SKIP_REGEX=""
RUN_TESTS_VERSION=""
EXIT_ON_ERROR=false

while [[ $# -gt 0 ]]; do
  case "${1}" in
    # Take in "--target-directory" flag for which test suite to run
    # "--target-directory ./config/tests/samples/..." = samples tests
    # "--target-directory ./pkg/... ./cmd/..." = integration tests
    --target-directory) TARGET_TESTS="${2:-}"; shift ;;
    # Take in the additional "--run-tests" flag for particular tests to run
    --run-tests)        RUN_TESTS_REGEX="-run-tests ${2:-}"; shift ;;
    # Take in the go test built-in "--run" flag for particular tests to run
    # This flag is only used to run e2e test(tests/e2e/unified_test.go),
    # because we do not have custom flag -run-tests set for it
    --go-test-run)      GO_TEST_RUN_REGEX="-run ${2:-}"; shift ;;
    # Take in the additional "--skip-tests" flag for particular tests to skip
    --skip-tests)       SKIP_TESTS_REGEX="-skip-tests ${2:-}"; shift ;;
    --go-test-skip)     GO_TEST_SKIP_REGEX="-skip ${2:-}"; shift ;;
    # Take in the additional "--run-tests-version" flag for particular tests to run
    --run-tests-version)   RUN_TESTS_VERSION="-run-tests-version ${2:-}"; shift ;;
    --exit-on-error)       EXIT_ON_ERROR=true;;
    *)                   echo "Unrecognized command line parameter: $1"; exit 1 ;;
  esac
  shift
done

set +e
if [ "${EXIT_ON_ERROR}" == true ]; then
    set -e
fi

if [[ "${TARGET_TESTS}" == "" ]]; then
    echo "No test directory given"
    exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel)"
source "${REPO_ROOT}/google-internal/scripts/shared-vars.sh"
cd ${REPO_ROOT}

services=("${SUPPORTED_SERVICES[@]}")

echo "Enabling services on project ${CLOUDSDK_CORE_PROJECT}:"
printf '  %s\n' "${services[@]}"
# gcloud.services.enable can only enable <20 services at a time
index=0
for (( ; index<${#services[@]}/20 ; index++ )); do
  gcloud services enable ${services[@]:20*${index}:20}
done

if (( ${#services[@]} > 20*${index} )); then
  gcloud services enable ${services[@]:20*${index}}
fi

# initialize App Engine app to test resources relying on it, e.g. CloudSchedulerJob and App Engine resources
retry --max-retries 5 --sleep-seconds 15 --command \
  "gcloud app create --region=us-west2"

PROJECT_ID=$(gcloud config get-value project)
echo "PROJECT_ID is ${PROJECT_ID}"
OAUTH2_TOKEN=$(gcloud auth print-access-token)
# create API specific google service accounts
curl -X GET -H "Authorization: Bearer ${OAUTH2_TOKEN}" \
  "https://www.googleapis.com/storage/v1/projects/${PROJECT_ID}/serviceAccount"
curl -X GET -H "Authorization: Bearer ${OAUTH2_TOKEN}" \
  "https://storagetransfer.googleapis.com/v1/googleServiceAccounts/${PROJECT_ID}"
curl -X POST -H "Authorization: Bearer ${OAUTH2_TOKEN}" \
  "https://serviceusage.googleapis.com/v1beta1/projects/${PROJECT_ID}/services/secretmanager.googleapis.com:generateServiceIdentity"

TEST_FOLDER_ID=${KCC_INTEGRATION_TESTS_FOLDER_ID}  \
  TEST_FOLDER_2_ID=${KCC_INTEGRATION_TESTS_2_FOLDER_ID} \
  TEST_ORG_ID=${ORGANIZATION_ID} \
  IAM_INTEGRATION_TESTS_ORGANIZATION_ID=${KCC_IAM_INTEGRATION_TESTS_ORGANIZATION_ID}  \
  ISOLATED_TEST_ORG_NAME=${KCC_INTEGRATION_TESTS_ISOLATED_ORGANIZATION_NAME} \
  TEST_BILLING_ACCOUNT_ID=${BILLING_ACCOUNT_ID}  \
  IAM_INTEGRATION_TESTS_BILLING_ACCOUNT_ID=${KCC_IAM_INTEGRATION_TESTS_BILLING_ACCOUNT_ID} \
  FIRE_STORE_TEST_PROJECT=${FIRESTORE_TEST_PROJECT}  \
  COMPUTE_IMAGE_TEST_PROJECT=${COMPUTE_IMAGE_TEST_PROJECT}  \
  CLOUD_FUNCTIONS_TEST_PROJECT=${CLOUD_FUNCTIONS_TEST_PROJECT}  \
  IDENTITY_PLATFORM_TEST_PROJECT=${IDENTITY_PLATFORM_TEST_PROJECT}  \
  INTERCONNECT_TEST_PROJECT=${INTERCONNECT_TEST_PROJECT}  \
  HIGH_CPU_QUOTA_TEST_PROJECT=${HIGH_CPU_QUOTA_TEST_PROJECT}  \
  RECAPTCHA_ENTERPRISE_TEST_PROJECT=${RECAPTCHA_ENTERPRISE_TEST_PROJECT}  \
  KCC_ATTACHED_CLUSTER_TEST_PROJECT=${KCC_ATTACHED_CLUSTER_TEST_PROJECT} \
  KCC_VERTEX_AI_INDEX_TEST_BUCKET=${KCC_VERTEX_AI_INDEX_TEST_BUCKET} \
  KCC_VERTEX_AI_INDEX_TEST_DATA_URI=${KCC_VERTEX_AI_INDEX_TEST_DATA_URI} \
  go test -v -parallel 20 ${TARGET_TESTS} \
    ${RUN_TESTS_REGEX} ${SKIP_TESTS_REGEX} ${GO_TEST_RUN_REGEX} ${GO_TEST_SKIP_REGEX} ${RUN_TESTS_VERSION}\
    -coverprofile cover.out \
    -tags=integration,performance \
    -timeout 180m
