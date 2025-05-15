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

# This script is for running the "iamworkforcepool" and "iamaccessboundary" integration test cases.
#
# Some IAM resources are in Public Preview, and the principle used to manage
# them needs to be a GSA under an allowlisted project.
#
# Run the "iamworkforcepool" tests _as_ the $IAM_WORKFORCE_TEST_GSA service account. This is a
# pre-created service account that is associated with an allowlisted project with the label
# WORKFORCE_POOLS_TRUSTED_TESTER.
#
# Run the "iamaccessboundarypolicy" tests _as_ the $IAM_ACCESS_BOUNDARY_TEST_GSA
# service account. This is a pre-created service account that is associated
# with an allowlisted project with the label ACCESS_BOUNDARY_TRUSTED_TESTER.

REPO_ROOT="$(git rev-parse --show-toplevel)"
source "${REPO_ROOT}/google-internal/scripts/shared-vars.sh"
cd ${REPO_ROOT}

CRUD_TEST_PACKAGE="github.com/GoogleCloudPlatform/k8s-config-connector/pkg/controller/dynamic"
TMP_IAM_WORKFORCE_CREDENTIALS=$(mktemp -t iam_gsa_credentials.XXXXXXXX)
TMP_IAM_ACCESS_BOUNDARY_CREDENTIALS=$(mktemp -t iam_gsa_credentials.XXXXXXXX)

# Delete the newly created GSA key because GSA keys can only have max 10 unique keys
function cleanup_sa_keys_workforce {
    echo "Deleting ${IAM_WORKFORCE_TEST_GSA}'s service account key ${TMP_IAM_WORKFORCE_SA_KEY_ID}..."
    gcloud iam service-accounts keys delete "${TMP_IAM_WORKFORCE_SA_KEY_ID}" --iam-account ${IAM_WORKFORCE_TEST_GSA} -q
}

function cleanup_sa_keys_accessboundary {
    echo "Deleting ${IAM_ACCESS_BOUNDARY_TEST_GSA}'s service account key ${TMP_IAM_ACCESS_BOUNDARY_SA_KEY_ID}..."
    gcloud iam service-accounts keys delete "${TMP_IAM_ACCESS_BOUNDARY_SA_KEY_ID}" --iam-account ${IAM_ACCESS_BOUNDARY_TEST_GSA} -q
}

function run_workforce_test {
    trap cleanup_sa_keys_workforce EXIT

    gcloud iam service-accounts keys create --iam-account "${IAM_WORKFORCE_TEST_GSA}" ${TMP_IAM_WORKFORCE_CREDENTIALS}
    TMP_IAM_WORKFORCE_SA_KEY_ID=$(jq --raw-output '.private_key_id' ${TMP_IAM_WORKFORCE_CREDENTIALS})
    export GOOGLE_APPLICATION_CREDENTIALS=${TMP_IAM_WORKFORCE_CREDENTIALS}

    TEST_ORG_ID=${ORGANIZATION_ID} \
      go test -v ${CRUD_TEST_PACKAGE} -run-tests "iamworkforcepool|oidcworkforcepoolprovider|samlworkforcepoolprovider" -tags=integration
}

function run_accessboundary_test {
    trap cleanup_sa_keys_accessboundary EXIT

    gcloud iam service-accounts keys create --iam-account "${IAM_ACCESS_BOUNDARY_TEST_GSA}" ${TMP_IAM_ACCESS_BOUNDARY_CREDENTIALS}
    TMP_IAM_ACCESS_BOUNDARY_SA_KEY_ID=$(jq --raw-output '.private_key_id' ${TMP_IAM_ACCESS_BOUNDARY_CREDENTIALS})
    export GOOGLE_APPLICATION_CREDENTIALS=${TMP_IAM_ACCESS_BOUNDARY_CREDENTIALS}

    TEST_ORG_ID=${ORGANIZATION_ID} \
      go test -timeout 60m -v ${CRUD_TEST_PACKAGE} -run-tests "iamaccessboundarypolicy" -tags=integration
}

run_workforce_test
run_accessboundary_test
