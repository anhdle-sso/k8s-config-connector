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

set -o errexit
set -o nounset
set -o pipefail
# export all variables so they can be referenced by sub processes like 'retry'
set -o allexport

# This script enables testing in a completely clean project with a new service account in that project.
# To use this script, write two scripts:
# 1. Test script, your-name-test.sh, this script should contain everything needed to run your tests, including enabling services, and the `go test ...` command
# 2. A wrapper script that calles your script from #1, it should likely only be a single line:
#       run-tests-new-project-identity.sh --command your-name-test.sh

REPO_ROOT="$(git rev-parse --show-toplevel)"
source "${REPO_ROOT}/google-internal/scripts/shared-vars.sh"
cd ${REPO_ROOT}

UNIQUE_ID=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 16 | head -n 1) || true
PROJECT_ID="${PROJECT_ID_PREFIX_FOR_TESTS}-${UNIQUE_ID}"
TEST_DEPENDENT_ORG_PROJECT_ID="${PROJECT_ID_PREFIX_FOR_TESTS}-${UNIQUE_ID}-01"
TEST_DEPENDENT_FOLDER_PROJECT_ID="${PROJECT_ID_PREFIX_FOR_TESTS}-${UNIQUE_ID}-02"
TEST_DEPENDENT_FOLDER_2_PROJECT_ID="${PROJECT_ID_PREFIX_FOR_TESTS}-${UNIQUE_ID}-03"
TEST_DEPENDENT_NO_NETWORK_PROJECT_ID="${PROJECT_ID_PREFIX_FOR_TESTS}-${UNIQUE_ID}-04"
export TEST_DEPENDENT_ORG_PROJECT_ID
export TEST_DEPENDENT_FOLDER_PROJECT_ID
export TEST_DEPENDENT_FOLDER_2_PROJECT_ID
export TEST_DEPENDENT_NO_NETWORK_PROJECT_ID

SERVICE_ACCOUNT_EMAIL="${GSA_ID_FOR_TESTS}@${PROJECT_ID}.iam.gserviceaccount.com"
IAM_MEMBER="serviceAccount:${SERVICE_ACCOUNT_EMAIL}"
export CLOUDSDK_CORE_DISABLE_PROMPTS=1
DO_CLEANUP="true"
TMP_GOOGLE_APPLICATION_CREDENTIALS=$(mktemp)

# turn off exporting of all variables
set +o allexport

COMMAND_TO_RUN=""
while [[ $# -gt 0 ]]; do
  case "${1}" in
    # The name of the test command to run, example:
    # --command ./google-internal/scripts/release/e2e-test.sh
    --command) COMMAND_TO_RUN="${2:-}"; shift ;;
    *)         echo "Unrecognized command line parameter: $1"; exit 1 ;;
  esac
  shift
done

# conditionally invoke a cleanup: cleanups are not run when the test command fails to allow for rerunning the command
function invoke_cleanup_func {
  if [[ ${DO_CLEANUP} == "false" ]]; then
    return
  fi
  $1
}

# adds the first argument to the stack of trap functions invoked on EXIT, functions are invoked LIFO order
function trap_exit_add {
    TRAP_ADD_CMD="invoke_cleanup_func ${1}"
    TRAP_NAME=EXIT
    CUR_TRAP=$(trap -p "${TRAP_NAME}")
    if [[ -z ${CUR_TRAP} ]]; then
      # if there is no trap defined, set the trap to the command
      trap "${TRAP_ADD_CMD}" ${TRAP_NAME}
    else
      trap -- "$(
          # helper fn to extract only the 'function' portion of the trap command
          extract_trap_cmd() { printf '%s\n' "$3"; }
          # print the new trap command
          printf '%s\n' "${TRAP_ADD_CMD}"
          # print existing trap command with newline
          eval "extract_trap_cmd ${CUR_TRAP}"
      )" "${TRAP_NAME}"
    fi
}

function cleanup_project {
    echo "Deleting project ${PROJECT_ID}..."
    gcloud projects delete ${PROJECT_ID} || true
    echo "Deleting project ${TEST_DEPENDENT_ORG_PROJECT_ID}..."
    gcloud projects delete ${TEST_DEPENDENT_ORG_PROJECT_ID} || true
    echo "Deleting project ${TEST_DEPENDENT_FOLDER_PROJECT_ID}..."
    gcloud projects delete ${TEST_DEPENDENT_FOLDER_PROJECT_ID} || true
    echo "Deleting project ${TEST_DEPENDENT_FOLDER_2_PROJECT_ID}..."
    gcloud projects delete ${TEST_DEPENDENT_FOLDER_2_PROJECT_ID} || true
    echo "Deleting project ${TEST_DEPENDENT_NO_NETWORK_PROJECT_ID}..."
    gcloud projects delete ${TEST_DEPENDENT_NO_NETWORK_PROJECT_ID} || true
}

function cleanup_shared_projects {
  echo "Removing shared project iam role bindings..."
  for SHARED_PROJ in ${SHARED_PROJECTS[@]};
  do
    retry --max-retries 7 --command "gcloud projects remove-iam-policy-binding ${SHARED_PROJ} --member ${IAM_MEMBER} --role roles/owner --no-user-output-enabled" || true
  done
}

function cleanup_organization_bindings {
  echo "Removing organization iam role bindings..."
  for ROLE in ${ORG_ROLES_FOR_TESTS[@]};
  do
    retry --max-retries 7 --command "gcloud organizations remove-iam-policy-binding ${ORGANIZATION_ID} --member ${IAM_MEMBER} --role ${ROLE} --no-user-output-enabled" || true
  done
}

function cleanup_billing_bindings {
  echo "Removing billing iam role bindings..."
  ACCOUNT=${BILLING_ACCOUNT_ID_FOR_BILLING_RESOURCES}
  for ROLE in ${BILLING_ACCOUNT_ROLES_FOR_TESTS[@]};
  do
    BILLING_IAM_FILE=$(mktemp)
    retry --max-retries 7 --command "
      gcloud beta billing accounts get-iam-policy ${ACCOUNT} --format json | jq '(.bindings[] | select(.role == \"${ROLE}\") | .members) -= [\"${IAM_MEMBER}\"]' > ${BILLING_IAM_FILE} &&
      gcloud beta billing accounts set-iam-policy ${ACCOUNT} ${BILLING_IAM_FILE} --no-user-output-enabled
    " || true
    rm ${BILLING_IAM_FILE}
  done
}

function cleanup_temporary_credentials {
  echo "Removing temporary credentials..."
  rm ${TMP_GOOGLE_APPLICATION_CREDENTIALS} || true
}

echo "Creating new projects..."
gcloud projects create ${PROJECT_ID} --labels="cnrm-test=true" --organization ${ORGANIZATION_ID}
gcloud projects create ${TEST_DEPENDENT_ORG_PROJECT_ID} --labels="cnrm-test=true" --organization ${ORGANIZATION_ID}
gcloud projects create ${TEST_DEPENDENT_FOLDER_PROJECT_ID} --labels="cnrm-test=true" --folder ${KCC_INTEGRATION_TESTS_FOLDER_ID}
gcloud projects create ${TEST_DEPENDENT_FOLDER_2_PROJECT_ID} --labels="cnrm-test=true" --folder ${KCC_INTEGRATION_TESTS_FOLDER_ID}
gcloud projects create ${TEST_DEPENDENT_NO_NETWORK_PROJECT_ID} --labels="cnrm-test=true" --folder ${KCC_INTEGRATION_TESTS_FOLDER_ID}
trap_exit_add cleanup_project

export CLOUDSDK_CORE_PROJECT=${PROJECT_ID}
gcloud beta billing projects link --billing-account ${BILLING_ACCOUNT_ID} ${PROJECT_ID}
gcloud beta billing projects link --billing-account ${BILLING_ACCOUNT_ID} ${TEST_DEPENDENT_ORG_PROJECT_ID}
gcloud beta billing projects link --billing-account ${BILLING_ACCOUNT_ID} ${TEST_DEPENDENT_FOLDER_PROJECT_ID}
gcloud beta billing projects link --billing-account ${BILLING_ACCOUNT_ID} ${TEST_DEPENDENT_FOLDER_2_PROJECT_ID}
gcloud beta billing projects link --billing-account ${BILLING_ACCOUNT_ID} ${TEST_DEPENDENT_NO_NETWORK_PROJECT_ID}

echo "Creating service account..."
gcloud iam service-accounts create ${GSA_ID_FOR_TESTS}

PROJECT_ROLES=(
  "roles/owner"
)
echo "Configuring service account permissions..."
for role in ${PROJECT_ROLES[@]};
do
  retry --max-retries 7 --command "gcloud projects add-iam-policy-binding ${PROJECT_ID} --no-user-output-enabled --member ${IAM_MEMBER} --role ${role}"
  retry --max-retries 7 --command "gcloud projects add-iam-policy-binding ${TEST_DEPENDENT_ORG_PROJECT_ID} --no-user-output-enabled --member ${IAM_MEMBER} --role ${role}"
  retry --max-retries 7 --command "gcloud projects add-iam-policy-binding ${TEST_DEPENDENT_FOLDER_PROJECT_ID} --no-user-output-enabled --member ${IAM_MEMBER} --role ${role}"
  retry --max-retries 7 --command "gcloud projects add-iam-policy-binding ${TEST_DEPENDENT_FOLDER_2_PROJECT_ID} --no-user-output-enabled --member ${IAM_MEMBER} --role ${role}"
  retry --max-retries 7 --command "gcloud projects add-iam-policy-binding ${TEST_DEPENDENT_NO_NETWORK_PROJECT_ID} --no-user-output-enabled --member ${IAM_MEMBER} --role ${role}"
done

# Add the service account as an owner to all of the projects which are shared across integration test runs
for SHARED_PROJ in ${SHARED_PROJECTS[@]};
do
  retry --max-retries 7 --command "gcloud projects add-iam-policy-binding ${SHARED_PROJ} --member ${IAM_MEMBER} --role roles/owner --no-user-output-enabled"
done
trap_exit_add cleanup_shared_projects

# Grant the service account the appropriate organization level roles
for ROLE in ${ORG_ROLES_FOR_TESTS[@]};
do
  retry --max-retries 14 --command "gcloud organizations add-iam-policy-binding ${ORGANIZATION_ID} --member ${IAM_MEMBER} --role ${ROLE} --no-user-output-enabled"
done
# This is for Organization level IAMPolicy integration test
# Note we don't need to "clean up" this binding. Because every time the test case for IAMPolicy runs, it resets the
# bindings to the same initial state (which effectively did the clean up.) An extra clean up step in this script will
# be targeting a non-exist binding, thus fail the test.
# Also we actually only need this assignment in periodic release test. There are three periodic runs per day and each
# run will erase any extra bindings added here during presubmit job.
retry --max-retries 14 --command "gcloud organizations add-iam-policy-binding ${KCC_IAM_INTEGRATION_TESTS_ORGANIZATION_ID} --member ${IAM_MEMBER} --role roles/resourcemanager.organizationAdmin --no-user-output-enabled"
trap_exit_add cleanup_organization_bindings

# Grant the service account the appropriate billing account level roles
ACCOUNT=${BILLING_ACCOUNT_ID_FOR_BILLING_RESOURCES}
for ROLE in ${BILLING_ACCOUNT_ROLES_FOR_TESTS[@]};
do
  BILLING_IAM_FILE=$(mktemp)
  retry --max-retries 7 --command "
    gcloud beta billing accounts get-iam-policy ${ACCOUNT} --format json | jq '(.bindings[] | select(.role == \"${ROLE}\") | .members) += [\"${IAM_MEMBER}\"]' > ${BILLING_IAM_FILE} &&
    gcloud beta billing accounts set-iam-policy ${ACCOUNT} ${BILLING_IAM_FILE} --no-user-output-enabled
  "
  rm ${BILLING_IAM_FILE}
done

# This is for BillingAccount IAMPolicy integration test
# Note we don't need to "clean up" this binding. Because every time the test case for IAMPolicy runs, it resets the
# bindings to the same initial state (which effectively did the clean up.) An extra clean up step in this script will
# be targeting a non-exist binding, thus fail the test.
# Also we actually only need this assignment in periodic release test. There are three periodic runs per day and each
# run will erase any extra bindings added here during presubmit job.
retry --max-retries 7 --command "gcloud beta billing accounts add-iam-policy-binding ${KCC_IAM_INTEGRATION_TESTS_BILLING_ACCOUNT_ID} --member ${IAM_MEMBER} --role roles/billing.admin --no-user-output-enabled"
trap_exit_add cleanup_billing_bindings

# Skip network quota validation because this is used to run tests in series.

echo "Creating service account credentials..."
gcloud iam service-accounts keys create --iam-account "${SERVICE_ACCOUNT_EMAIL}" ${TMP_GOOGLE_APPLICATION_CREDENTIALS}
export GOOGLE_APPLICATION_CREDENTIALS=${TMP_GOOGLE_APPLICATION_CREDENTIALS}
trap_exit_add cleanup_temporary_credentials

if eval ${COMMAND_TO_RUN}; then
  echo "==================================================================================="
  echo "Command run successfully: ${COMMAND_TO_RUN}"
  echo "Tests passed! Project will be deleted."
else
  RESULT=$?
  DO_CLEANUP="false"
  echo "==================================================================================="
  echo "Tests failed, to re-run use the following to run with the same environment:"
  echo ""
  echo "export GOOGLE_APPLICATION_CREDENTIALS=${GOOGLE_APPLICATION_CREDENTIALS}"
  echo "export CLOUDSDK_CORE_PROJECT=${PROJECT_ID}"
  echo "${COMMAND_TO_RUN}"
  echo ""
  exit ${RESULT}
fi
