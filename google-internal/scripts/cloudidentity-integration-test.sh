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


set -o errexit
set -o nounset
set -o pipefail

# This script is for running the "cloudidentitygroup" and "cloudidentitymembership"
# integration test cases. The "cloudidentitygroup" and "cloudidentitymembership"
# integration tests needs to run on a particular service account with unique
# set-up steps.

# Run the "cloudidentitygroup" and "cloudidentitymembership" tests _as_ the
# $CLOUD_IDENTITY_SERVICE_ACCOUNT_EMAIL service account. This is a pre-created
# service account that has the roleAssignment needed to access the kcc.joonix.net
# test organization.

REPO_ROOT="$(git rev-parse --show-toplevel)"
source "${REPO_ROOT}/google-internal/scripts/shared-vars.sh"
cd ${REPO_ROOT}

CRUD_TEST_PACKAGE="github.com/GoogleCloudPlatform/k8s-config-connector/pkg/controller/dynamic"
CLOUDIDENTITY_SERVICE_ACCOUNT_EMAIL="cnrm-system@cnrm-test-cloudidentity.iam.gserviceaccount.com"
TMP_GOOGLE_APPLICATION_CREDENTIALS=$(mktemp -t cloud_identity_gsa_credentials.XXXXXXXX)

# Delete the newly created GSA key because GSA keys can only have max 10 unique keys
function cleanup_sa_keys {
    echo "Deleting ${CLOUDIDENTITY_SERVICE_ACCOUNT_EMAIL}'s service account key ${TMP_SA_KEY_ID}..."
    gcloud iam service-accounts keys delete "${TMP_SA_KEY_ID}" --iam-account ${CLOUDIDENTITY_SERVICE_ACCOUNT_EMAIL} -q
}

gcloud iam service-accounts keys create --iam-account "${CLOUDIDENTITY_SERVICE_ACCOUNT_EMAIL}" ${TMP_GOOGLE_APPLICATION_CREDENTIALS}
export GOOGLE_APPLICATION_CREDENTIALS=${TMP_GOOGLE_APPLICATION_CREDENTIALS}
TMP_SA_KEY_ID=$(jq --raw-output '.private_key_id' ${TMP_GOOGLE_APPLICATION_CREDENTIALS})

trap cleanup_sa_keys EXIT

ISOLATED_TEST_ORG_NAME=${KCC_INTEGRATION_TESTS_ISOLATED_ORGANIZATION_NAME} \
  go test -v ${CRUD_TEST_PACKAGE} -run-tests "cloudidentitymembership|cloudidentitygroup" -tags=integration
