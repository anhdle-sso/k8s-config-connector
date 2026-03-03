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

# This script updates files used for our public docs
# at https://source.corp.google.com/piper///depot/google3/googledata/devsite/site-cloud/en/config-connector

set -o errexit
set -o nounset
set -o pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
source "${REPO_ROOT}/google-internal/scripts/shared-vars.sh"
THIS_SCRIPTS_DIR=$(dirname "${BASH_SOURCE}")

# Parse arguments
PREVIOUS_RELEASE_TAG="${1:-}"
CURRENT_RELEASE_TAG="${2:-}"

if [[ -z "${PREVIOUS_RELEASE_TAG}" ]] || [[ -z "${CURRENT_RELEASE_TAG}" ]]; then
  echo "Usage: $0 <previous-release-tag> <current-release-tag>"
  echo "Example: $0 github/v1.125.0 github/v1.126.0"
  exit 1
fi

# Validate tag format "github/vx.xxx.x"
TAG_REGEX="^github/v[0-9]+\.[0-9]+\.[0-9]+$"
if ! [[ "${PREVIOUS_RELEASE_TAG}" =~ ${TAG_REGEX} ]]; then
  echo "ERROR: PREVIOUS_RELEASE_TAG '${PREVIOUS_RELEASE_TAG}' must be in the format 'github/vx.xxx.x'."
  exit 1
fi

if ! [[ "${CURRENT_RELEASE_TAG}" =~ ${TAG_REGEX} ]]; then
  echo "ERROR: CURRENT_RELEASE_TAG '${CURRENT_RELEASE_TAG}' must be in the format 'github/vx.xxx.x'."
  exit 1
fi

# Prepare google3 docs submission
cd $REPO_ROOT
CLIENT_NAME=configconnector_resource_doc_$(date +%s)
p4 g4d -f $CLIENT_NAME
GOOGLE3_DOCS_DIR=/google/src/cloud/$USER/$CLIENT_NAME/google3/third_party/devsite/cloud/en/config-connector/docs
# Resource reference docs and lists
# We use git diff to identify and apply changes granularly instead of copying them over directly.
echo "Applying granular updates from ${PREVIOUS_RELEASE_TAG} to ${CURRENT_RELEASE_TAG}..."

while read -r STATUS FILE; do
  DEST_FILE=""
  case "${FILE}" in
    scripts/generate-google3-docs/resource-reference/generated/resource-docs*)
      DEST_FILE="${GOOGLE3_DOCS_DIR}/reference/${FILE#scripts/generate-google3-docs/resource-reference/generated/}"
      ;;
    scripts/generate-google3-docs/resource-reference/_toc.yaml)
      DEST_FILE="${GOOGLE3_DOCS_DIR}/reference/_toc.yaml"
      ;;
    scripts/generate-google3-docs/resource-reference/overview.md)
      DEST_FILE="${GOOGLE3_DOCS_DIR}/reference/overview.md"
      ;;
    scripts/generate-google3-docs/resource-lists/generated/*)
      DEST_FILE="${GOOGLE3_DOCS_DIR}/how-to/${FILE#scripts/generate-google3-docs/resource-lists/generated/}"
      ;;
  esac

  if [[ -n "${DEST_FILE}" ]]; then
    case "${STATUS}" in
      A|M)
        if [[ "${STATUS}" == "A" ]]; then
          echo "Adding ${DEST_FILE}..."
          mkdir -p "$(dirname "${DEST_FILE}")"
        else
          echo "Updating ${DEST_FILE}..."
          (cd "${GOOGLE3_DOCS_DIR}" && p4 edit "${DEST_FILE}")
        fi
        git show "${CURRENT_RELEASE_TAG}:${FILE}" > "${DEST_FILE}"
        if [[ "${STATUS}" == "A" ]]; then
          (cd "${GOOGLE3_DOCS_DIR}" && p4 add "${DEST_FILE}")
        fi
        ;;
      D)
        echo "Deleting ${DEST_FILE}..."
        (cd "${GOOGLE3_DOCS_DIR}" && p4 delete "${DEST_FILE}")
        ;;
    esac
  fi
done < <(git diff --name-status "${PREVIOUS_RELEASE_TAG}" "${CURRENT_RELEASE_TAG}")

cd ${GOOGLE3_DOCS_DIR}
p4 reopen
MSG=$(p4 diffstats 2>&1)
if [[ ${MSG} =~ "File(s) not opened on this client" ]]; then
    echo "No changes to resource docs"
    p4 citc -d $CLIENT_NAME
else
  p4 change --desc "Updating resource docs from ${PREVIOUS_RELEASE_TAG} to ${CURRENT_RELEASE_TAG}

BRANDING_VIOLATION_REASON=Auto-generated descriptions
DISABLE_DISRESPECTFUL_TERMS=Auto-generated descriptions
DISABLE_PRIVATE_KEY_CHECK=Test keys used for example purposes only
DISABLE_HEADING_QUOTES_CHECK=Test cannot distinguish Markdown headers and comments in YAML snippets
"
fi