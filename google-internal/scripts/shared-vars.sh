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

REPO_ROOT="$(git rev-parse --show-toplevel)"
source ${REPO_ROOT}/scripts/shared-vars-public.sh

# GCP IDs
ORGANIZATION_ID=128653134652 # The ID of the "deployment-manager.net" org
BILLING_ACCOUNT_ID="01BD15-3BAB95-35F231" # CNRM Testing billing account
BILLING_ACCOUNT_ID_FOR_BILLING_RESOURCES="0162D7-7B0CB6-ED962E" # The "KCC Test Account for Billing resources integ test only" account used in KCC integration tests for Billing resources only; used by test cases "calendarbudget" and "custombudget".
KCC_IAM_INTEGRATION_TESTS_BILLING_ACCOUNT_ID="01FB3D-35C560-C7B7A1" # The "Integration Test" account under "configconnector.joonix.net" org; used by test case "billingaccountiampolicy"
KCC_INTEGRATION_TESTS_FOLDER_ID="16031899883" # The "KCC Integration Tests" folder in the "deployment-manager.net" org
KCC_INTEGRATION_TESTS_2_FOLDER_ID="224594885071" # The the "KCC Integration Tests 2" folder in the "deployment-manager.net" org; used by test cases "projectmovedfoldertofolder" and "foldermovedfoldertofolder".
KCC_IAM_INTEGRATION_TESTS_ORGANIZATION_ID="929083500066" # The "configconnector.joonix.net" org; used by test case "organizationiampolicy"
KCC_INTEGRATION_TESTS_ISOLATED_ORGANIZATION_NAME="kcc.joonix.net" # The isolated KCC test organization
# Pre-created test projects
FIRESTORE_TEST_PROJECT="cnrm-test-firestore"
CLOUD_FUNCTIONS_TEST_PROJECT="kcc-cloud-functions"
DLP_TEST_PROJECT="kcc-dlp"
IDENTITY_PLATFORM_TEST_PROJECT="kcc-identity-platform"
INTERCONNECT_TEST_PROJECT="kcc-interconnect"
HIGH_CPU_QUOTA_TEST_PROJECT="kcc-highcpuquota"
RECAPTCHA_ENTERPRISE_TEST_PROJECT="kcc-recaptcha-enterprise"
KCC_ATTACHED_CLUSTER_TEST_PROJECT="kcc-attached-cluster-test"
# IAM Workforce Pools integration test Service Account
IAM_WORKFORCE_TEST_GSA="cnrm-system@cnrm-test-iam.iam.gserviceaccount.com"
# IAM Access Boundary Policy integration test Service Account
IAM_ACCESS_BOUNDARY_TEST_GSA="cnrm-system@kcc-access-boundary.iam.gserviceaccount.com"

# Integration test variables
PROJECT_ID_PREFIX_FOR_TESTS="cnrm-test"
GSA_ID_FOR_TESTS="integration-test"
ORG_ROLES_FOR_TESTS=(
  roles/accesscontextmanager.policyAdmin
  roles/compute.orgFirewallPolicyAdmin
  roles/compute.orgSecurityResourceAdmin
  roles/compute.xpnAdmin
  roles/dlp.admin
  roles/eventarc.admin
  roles/iam.accessBoundaryAdmin
  roles/iam.organizationRoleAdmin
  roles/logging.admin
  roles/orgpolicy.policyAdmin
  roles/resourcemanager.folderAdmin
  roles/resourcemanager.organizationAdmin
  roles/resourcemanager.projectCreator
  roles/resourcemanager.projectDeleter
  roles/resourcemanager.tagAdmin
  roles/resourcemanager.tagUser
  roles/storage.objectAdmin
)
# some roles use the billing account as the top level entity, rather than
# the organization. For these entities, we need to use the
# billing account id, rather than organization ID to identify the full list.
BILLING_ACCOUNT_ROLES_FOR_TESTS=(
  roles/billing.admin
  roles/logging.admin
)

# these projects are shared across all tests
SHARED_PROJECTS=(
  ${FIRESTORE_TEST_PROJECT}
  ${CLOUD_FUNCTIONS_TEST_PROJECT}
  ${DLP_TEST_PROJECT}
  ${IDENTITY_PLATFORM_TEST_PROJECT}
  ${INTERCONNECT_TEST_PROJECT}
  ${HIGH_CPU_QUOTA_TEST_PROJECT}
  ${RECAPTCHA_ENTERPRISE_TEST_PROJECT}
  ${KCC_ATTACHED_CLUSTER_TEST_PROJECT}
)

# package names and locations
CLI_TARBALL_NAME=cli.tar.gz
CLI_TARBALL_BUILD_PATH=${BIN_DIR}/${CLI_TARBALL_NAME}

# repository
SHORT_SHA="$(cd ${REPO_ROOT}; git rev-parse --short=7 HEAD)"

# gcs buckets and paths
INTERNAL_RELEASE_BUCKET=cnrm-internal
RELEASE_BUCKET=cnrm
GCS_SHA_DEST=gs://${INTERNAL_RELEASE_BUCKET}/${SHORT_SHA}
GCS_LATEST_DEST=gs://${INTERNAL_RELEASE_BUCKET}/latest
DLP_TEST_BUCKET=aaa-dont-delete-kcc-dlp-testing

RETRY_CMD=${REPO_ROOT}/hack/retry
 
function retry() {
  ${RETRY_CMD} "$@"
}
