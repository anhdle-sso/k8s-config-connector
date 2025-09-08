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


# This script cleans up GCP resources that were created by tests, but which
# tests failed to clean up. Unlike cleanup-leaked-test-resources.sh, this
# script also cleans up resources that may be in use by currently running
# tests, since the intention behind this script is to clean up resources that
# don't provide enough information about when they were created (e.g. IAM
# roles).
#
# This script should only be run during non-working hours or when we really
# need to clean up resources now (e.g. due to resource quotas having been
# exceeded).
#
# This script is a complement to cleanup-leaked-test-resources.sh which can be
# (and is periodically) run during working hours.

set -o errexit
set -o nounset
set -o pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
source "${REPO_ROOT}/google-internal/scripts/shared-vars.sh"
cd ${REPO_ROOT}

function main {
  delete_org_level_iam_custom_roles
  cleanup_iam_workforce_pools
  cleanup_iam_workforce_pools_sa_keys
  cleanup_billing_budgets
  cleanup_dlp_output
  cleanup_firewall_policies
}

function delete_org_level_iam_custom_roles {
  echo "Searching for all the org-level IAM roles to delete..."
  ROLE_NAMES=$(
    gcloud iam roles list \
      --organization ${ORGANIZATION_ID} \
      --filter="title=\"Example Organization-Level Custom Role\"" \
      --no-show-deleted \
      --format "value(name)"
  )

  if [[ -z "${ROLE_NAMES}" ]]
  then
    echo "No org-level IAM roles found."
  else
    for ROLE_NAME in ${ROLE_NAMES}; do
      # Extract out the role ID before the deletion because the returned role
      # names are in the format of "organizations/[ORG_ID]/roles/[ROLE_ID]".
      delimiter=/roles/
      ROLE_ID=${ROLE_NAME#*$delimiter}

      echo "Deleting Org-level IAM custom role ${ROLE_ID}..."
      gcloud iam roles delete ${ROLE_ID} --organization ${ORGANIZATION_ID}
    done
  fi
}

# Clean up unused workforce pools in deployment-manager.net test organization.
function cleanup_iam_workforce_pools {
  WORKFORCE_POOL_NAMES=$(
    gcloud iam workforce-pools list \
      --location=global \
      --organization=${ORGANIZATION_ID} \
      --format "value(name)"
  )

  if [[ -z "${WORKFORCE_POOL_NAMES}" ]]
  then
    echo "No workforce pools found for organization ${ORGANIZATION_ID}."
  else
    for WORKFORCE_POOL_NAME in ${WORKFORCE_POOL_NAMES}; do
      echo "Deleting ${WORKFORCE_POOL_NAME} for organization ${ORGANIZATION_ID}..."
      gcloud iam workforce-pools delete ${WORKFORCE_POOL_NAME} \
        --location=global -q
    done
  fi
}

# Clear out unused keys for the service account ${IAM_WORKFORCE_TEST_GSA}
function cleanup_iam_workforce_pools_sa_keys {
  KEY_NAMES=$(
    gcloud iam service-accounts keys list \
      --iam-account ${IAM_WORKFORCE_TEST_GSA} \
      --managed-by user \
      --format "value(name)"
  )

  if [[ -z "${KEY_NAMES}" ]]
  then
    echo "No keys found for ${IAM_WORKFORCE_TEST_GSA}."
  else
    for KEY_NAME in ${KEY_NAMES}; do
      echo "Deleting key ${KEY_NAME} for SA ${IAM_WORKFORCE_TEST_GSA}..."
      gcloud iam service-accounts keys delete ${KEY_NAME} \
        --iam-account=${IAM_WORKFORCE_TEST_GSA} -q
    done
  fi
}

function cleanup_billing_budgets {
  BUDGET_NAMES=$(
    gcloud billing budgets list \
      --billing-account=${BILLING_ACCOUNT_ID_FOR_BILLING_RESOURCES} \
      --format "value(name)"
  )
  if [[ -z "${BUDGET_NAMES}" ]]
  then
    echo "No budget found for billing account ${BILLING_ACCOUNT_ID_FOR_BILLING_RESOURCES}."
  else
    for BUDGET_NAME in ${BUDGET_NAMES}; do
      echo "Deleting budget ${BUDGET_NAME} for billing account ${BILLING_ACCOUNT_ID_FOR_BILLING_RESOURCES}..."
      gcloud billing budgets delete ${BUDGET_NAME} --quiet
      sleep .5  # Billing Budget API has a quota limit of 100 write calls per minute.
    done
  fi
}

function cleanup_dlp_output {
  echo "Cleaning up DLP output in test bucket gs://${DLP_TEST_BUCKET}..."
  for folder in "large-custom-dictionary-1" "large-custom-dictionary-2";
  do
    # The rm command always output using stderr (so weird).
    # When objects are successfully deleted, output are in stderr with exit code 0.
    # When objects can't be found, output are in stderr with exit code 1.
    # To handle it properly:
    # * First, check if exit code of running the rm command is 0:
    #   |-> * Yes, nothing needs to be done. The objects have been cleaned up successfully.
    #   |-> * No, check if the output from stderr does NOT match the expected error message when no objects are found:
    #         "Removing objects:\n  \n\n
    #         Removing managed folders:\n  \n
    #         failed.\n
    #         ERROR: (gcloud.storage.rm) The following URLs matched no objects or files:\n
    #         gs://${DLP_TEST_BUCKET}/${folder}/dlp_api_stored_info_types/".
    #         |-> * Yes, something unexpected happened. Return 1.
    #         |-> * No, nothing needs to be done.

    url="gs://${DLP_TEST_BUCKET}/${folder}/dlp_api_stored_info_types/"
    echo "Cleaning up DLP output under ${url}..."
    if stderr=$(gcloud storage rm --recursive ${url} 2>&1); then
      echo "Successfully cleaned up DLP output under ${url}!"
    else
      err_msg_str="ERROR: (gcloud.storage.rm) The following URLs matched no objects or files:\n\
gs://${DLP_TEST_BUCKET}/${folder}/dlp_api_stored_info_types/"
      err_msg_with_newline=$(echo -e "${err_msg_str}")
      if [[ "${stderr}" =~ "${err_msg_with_newline}" ]]; then
        echo "No need to clean up output under ${url}."
      else
        echo "Unexpected error removing objects under ${url}: ${stderr}"
        return 1
      fi
    fi
  done
  echo "Successfully cleaned up DLP output in test bucket gs://${DLP_TEST_BUCKET}!"
}

# Cleanup remaining test firewall policy in test org.
# UNASSOCIATED_HIERARCHICAL_FIREWALL_POLICIES quota is 50.0 globally.
# Filter test firewall policy by checking its display name regex with format
# "firewallpolicy-{uniqueID}", unique ID is generated that has exactly 15 characters.
function cleanup_firewall_policies {
  echo "Cleaning up test firewall policy in organization ${ORGANIZATION_ID}..."
  POLICY_NAMES=$(
    gcloud compute firewall-policies list \
    --organization=${ORGANIZATION_ID} \
    --filter="display_name~^firewallpolicy-[a-z0-9]{15}$" \
    --format "value(display_name)"
  )
  if [[ -z "${POLICY_NAMES}" ]]
  then
    echo "No test firewall policy found in organization ${ORGANIZATION_ID}."
  else
    for POLICY_NAME in ${POLICY_NAMES}; do
      echo "Deleting test firewall policy ${POLICY_NAME} in organization ${ORGANIZATION_ID}..."
      gcloud compute firewall-policies delete ${POLICY_NAME} \
      --organization=${ORGANIZATION_ID} \
      --quiet
    done
  fi
  echo "Successfully cleaned up test firewall policies in organization ${ORGANIZATION_ID}."
}

main
