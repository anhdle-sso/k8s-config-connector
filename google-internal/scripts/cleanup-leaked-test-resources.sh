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
# tests failed to clean up.

set -o errexit
set -o nounset
set -o pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
source "${REPO_ROOT}/google-internal/scripts/shared-vars.sh"
cd ${REPO_ROOT}

IAM_MEMBER_PREFIX_FOR_TEST_SERVICE_ACCS="serviceAccount:${GSA_ID_FOR_TESTS}@${PROJECT_ID_PREFIX_FOR_TESTS}"

function main {
  echo "Searching for test projects over 8 hours old to delete..."
  PROJECT_IDS=$(gcloud projects list --filter="labels.cnrm-test=true AND createTime<-P8H" --format "value(projectId)")
  if [[ -z "${PROJECT_IDS}" ]]
  then
      echo "No old projects found."
  else
      for PID in ${PROJECT_IDS}; do
          # Skip deletion of projects that have already been marked for deletion since deleting
          # projects that have already been marked for deletion will yield an error.
          LIFECYCLE_STATE=$(gcloud projects describe ${PID} --format "value(lifecycleState)")
          if [[ "${LIFECYCLE_STATE}" == "DELETE_REQUESTED" ]]; then
              echo "Skipping deletion of project with id '${PID}' since it has already been marked for deletion"
              continue
          fi

          echo "Deleting project with id '${PID}'"

          # Enabling a project as a Shared VPC host automatically puts a lien preventing deletion.
          # Remove this lien if it is present first.
          LIEN=$(gcloud alpha resource-manager liens list --project ${PID} --format "value(name)")
          if [[ -n "${LIEN}" ]]; then
              gcloud alpha resource-manager liens delete ${LIEN} --project ${PID}
        fi
        gcloud projects delete ${PID} -q
    done
  fi

  remove_members_from_deleted_projects_from_roles

  remove_deleted_members_from_roles

  cleanup_gcp_folders "--organization=${ORGANIZATION_ID}"
  cleanup_gcp_folders "--folder=${KCC_INTEGRATION_TESTS_FOLDER_ID}"
  cleanup_gcp_folders "--folder=${KCC_INTEGRATION_TESTS_2_FOLDER_ID}"
  cleanup_org_level_logging_log_views "--organization=${ORGANIZATION_ID}"

  cleanup_test_attached_cluster
}

# remove_deleted_members_from_roles removes members of roles that
# are marked as deleted
function remove_deleted_members_from_roles {
  echo "Removing members from deleted GCP projects from shared roles..."
  tmp=$(mktemp)
  trap "rm -f $tmp" EXIT

  echo "removing deleted members from organization ${ORGANIZATION_ID}..."
  gcloud organizations get-iam-policy "${ORGANIZATION_ID}" --format=json \
    | jq '.bindings[].members |= [.[] | select(startswith("deleted")| not)]' > "$tmp"
  gcloud organizations set-iam-policy "${ORGANIZATION_ID}" "$tmp" --no-user-output-enabled

  echo "removing deleted members from billing account ${BILLING_ACCOUNT_ID_FOR_BILLING_RESOURCES}..."
  gcloud beta billing accounts get-iam-policy "${BILLING_ACCOUNT_ID_FOR_BILLING_RESOURCES}" --format=json \
    | jq '.bindings[].members |= [.[] | select(startswith("deleted")| not)]' > "$tmp"
  gcloud beta billing accounts set-iam-policy "${BILLING_ACCOUNT_ID_FOR_BILLING_RESOURCES}" "$tmp" --no-user-output-enabled

  rm -f "$tmp"
  trap - EXIT
}

# remove_members_from_deleted_projects_from_roles removes roles bindings to service accounts
# which belong to deleted projects.
#
# Resources for a project are not deleted immediately upon a delete request, instead waiting
# up to 60 days as defined in go/udrdp. Thus, to ensure more aggressive cleanup, this function is
# used to proactively remove bindings before a service account is marked as deleted.
function remove_members_from_deleted_projects_from_roles {
  local service_accounts_with_role

  echo "Searching for organization iam-policy-bindings to remove..."
  for role in "${ORG_ROLES_FOR_TESTS[@]}";
  do
    service_accounts_with_role=$(get_service_accounts_with_role "organizations" "${ORGANIZATION_ID}" "$role")

    for member in ${service_accounts_with_role};
    do
      remove_binding_if_deleted_project "organizations" "${ORGANIZATION_ID}" "$role" "$member"
    done
  done

  echo "Searching for billing account iam-policy-bindings to remove..."
  for account in ${BILLING_ACCOUNT_ID} ${BILLING_ACCOUNT_ID_FOR_BILLING_RESOURCES};
  do
    for role in "${BILLING_ACCOUNT_ROLES_FOR_TESTS[@]}";
    do
      service_accounts_with_role=$(get_service_accounts_with_role "beta billing accounts" "$account" "$role")

      for member in ${service_accounts_with_role};
      do
        remove_binding_if_deleted_project "beta billing accounts" "$account" "$role" "$member"
      done
    done
  done

  echo "Searching for shared project bindings to remove..."
  for project_id in "${SHARED_PROJECTS[@]}";
  do
    service_accounts_with_role=$(get_service_accounts_with_role "projects" "${project_id}" "roles/owner")

    for member in ${service_accounts_with_role};
    do
      remove_binding_if_deleted_project "projects" "${project_id}" "roles/owner" "$member"
    done
  done
}

# get_service_accounts_with_roles retrieves a list of members
# whose service accounts were created for KCC integration tests are
# included (i.e. those that have an email address that starts with
# "${GSA_ID_FOR_TESTS}@${PROJECT_ID_PREFIX_FOR_TESTS}")
function get_service_accounts_with_role {
  local before_iam_policy_args="$1"
  local resource_id="$2"
  local role="$3"
  local result
  result="$(gcloud ${before_iam_policy_args} get-iam-policy "${resource_id}" --format="json" \
    | jq --raw-output \
      ".bindings[] | select(.role == \"${role}\") | .members[] | select(startswith(\"${IAM_MEMBER_PREFIX_FOR_TEST_SERVICE_ACCS}\"))")"
  local result_code=$?
  echo "$result"
  return $result_code
}

# remove_binding_if_deleted_project removes
# the desired role binding if the project that the KCC
# integration test service account is a part of has already
# been deleted.
function remove_binding_if_deleted_project {
  local before_iam_policy_args="$1"
  local resource_id="$2"
  local role="$3"
  local member="$4"
  local project_id
  project_id=$(echo "${member}" | grep -oE "${PROJECT_ID_PREFIX_FOR_TESTS}-[a-z0-9]+")
  if is_deleted_test_project "$project_id"; then
    echo "Removing iam-policy-binding for '${resource_id}' which binds '${member}' to role '${role}'"
    # sometimes the removal of the binding fails with the following errors:
    # ERROR: (gcloud.organizations.remove-iam-policy-binding) Policy binding with the specified member, role, and condition not found!
    # ERROR: (gcloud.beta.billing.accounts.remove-iam-policy-binding) Policy binding with the specified member and role not found!
    #
    # adding success-regex to pass with that error, since it's a red herring as the desired state of the binding
    # being removed has been achieved.
    retry --max-retries 5 --sleep-seconds 15 --success-regex ".*\(condition not found\|role not found\).*" --command \
      "gcloud $before_iam_policy_args remove-iam-policy-binding '${resource_id}' --role '${role}' --member '${member}' --no-user-output-enabled"
  fi
}

function is_deleted_test_project {
  local project_id="$1"
  local lifecycle_state is_test_proj
  lifecycle_state=$(gcloud projects describe "${project_id}" --format "value(lifecycleState)")
  is_test_proj=$(gcloud projects describe "${project_id}" --format "value(labels.cnrm-test)")
  if [ "${lifecycle_state}" == "DELETE_REQUESTED" ] && [ "${is_test_proj}" == "true" ]; then
    return 0
  fi
  return 1
}

# cleanup_gcp_folders removes folders that are beyond 1 days old,
# as the limit for total folders under an organization is 300.
#
# This function only cleans folders that have the current convention
# of KCC {20 random alphanumeric characters}.
function cleanup_gcp_folders {
  folder_list_args="$1"
  echo "Cleaning up folders older than 1 days in '$folder_list_args'..."
  # folder_list_args is not in quotes on purpose, to allow expanding arguments
  folder_ids_to_delete=$(
    gcloud resource-manager folders list \
      $folder_list_args \
      --filter='displayName~^KCC.[a-z0-9]+ AND createTime < -p1d' \
      --format='csv[terminator=" ",no-heading](name)'
    )
  for folder_id in $folder_ids_to_delete;
  do
    gcloud resource-manager folders delete "$folder_id"
  done
}

# cleanup_org_level_logging_log_views removes logging log views that are more
# than 1 day old under the _Default bucket in the given organization, as the
# limit for total log views under a log bucket is 30.
function cleanup_org_level_logging_log_views {
  logging_log_view_parent_org="$1"
  parent_args="--bucket _Default --location global $logging_log_view_parent_org"

  echo "Cleaning up logging log views older than 1 day in '$parent_args'..."
  # The _AllLogs and _Default views are created by the service and NOT editable.
  view_ids_to_delete=$(
    gcloud logging views list \
      $parent_args \
      --filter='createTime < -p1d' \
      --format='value(VIEW_ID)' \
      | { grep -vE "(_Default|_AllLogs)" \
          || [[ $? == 1 ]]; }  # grep returns 1 on no match found; convert exit
                               # code to 0 to ensure script doesn't exit due to
                               # non-zero exit code
    )
  for view_id in $view_ids_to_delete;
  do
    gcloud logging views delete "$view_id" \
      $parent_args
  done
}

# Ensure that any underlying test attached cluster resources are properly removed after the test is finished.
# GCP resource/attached cluster name: kcc-attached-cluster
# GCP test project id: kcc-attached-cluster-test
function cleanup_test_attached_cluster {
  echo "Cleaning up test attached cluster..."
  COUNT=$(gcloud container attached clusters list --location us-west1  --project kcc-attached-cluster-test \
  --filter "name=projects/461360080950/locations/us-west1/attachedClusters/kcc-attached-cluster AND createTime < -P1H" \
  --format json | jq length)
    if [ "${COUNT}" == 0 ]
    then
        echo "No test attached cluster found."
    else
        echo "Deleting test attached cluster..."
        gcloud container attached clusters delete kcc-attached-cluster \
        --ignore-errors --allow-missing --location=us-west1 --project kcc-attached-cluster-test --quiet
    fi
}

main
