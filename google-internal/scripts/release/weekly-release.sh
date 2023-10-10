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

REPO_ROOT="$(git rev-parse --show-toplevel)"
source "${REPO_ROOT}/google-internal/scripts/shared-vars.sh"

while [[ $# -gt 0 ]]; do
  case "${1}" in
    --release-sha)  RELEASE_SHA="${2:-}"; shift ;;
    *)              echo "Unrecognized command line parameter: $1"; exit 1 ;;
  esac
  shift
done

# Ensure that the user has run gcert so we can communicate with GoB
if command -v prodcertstatus; then
  prodcertstatus
  if [[ $? -gt 0 ]]; then
      echo "ERROR: Please run gcert."
      exit 1
  fi
else
  gcertstatus
  if [[ $? -gt 0 ]]; then
      echo "ERROR: Please run gcert."
      exit 1
  fi
fi

# Check if the release SHA was given
RELEASE_SHA="${RELEASE_SHA:-"$(gcloud beta runtime-config configs variables get-value latest-version --config-name cnrm-eap --project cnrm-eap)"}"
INTERNAL_BUCKET=cnrm-internal

cd ${REPO_ROOT}

# Checkout the repo in a 'detached HEAD' state at the desired release SHA.
CHANGED_FILE_COUNT=$(git diff --name-only | wc -l)
NEW_FILE_COUNT=$(git ls-files --others --exclude-standard | wc -l)
if [[ "${CHANGED_FILE_COUNT}" != "0" ]] || [[ "${NEW_FILE_COUNT}" != "0" ]]; then
    echo "ERROR: Cannot checkout release SHA with current uncommitted changes."
    exit 1
fi
CURRENT_GIT_LOCATION="$(git rev-parse --abbrev-ref HEAD)"
if [[ "${CURRENT_GIT_LOCATION}" == "HEAD" ]]; then
    # We're currently already in a 'detached HEAD' state. Instead, store the SHA so we can
    # get back to it.
    CURRENT_GIT_LOCATION="$(git rev-parse HEAD)"
fi
function cleanup() {
  cd ${REPO_ROOT}
  git checkout ${CURRENT_GIT_LOCATION}
}
trap cleanup EXIT
git checkout ${RELEASE_SHA}

# download the latest release bundle and get the associated version
TMP_DIR=$(mktemp -d)
gsutil cp gs://${INTERNAL_BUCKET}/${RELEASE_SHA}/release-bundle.tar.gz ${TMP_DIR}
tar xvf ${TMP_DIR}/release-bundle.tar.gz -C ${TMP_DIR}
VERSION=$(cat ${TMP_DIR}/version)
rm -Rf ${TMP_DIR}

while true; do
  read -p "The latest build has version ${VERSION}. Continue? [Y/n]: " yn
  case $yn in
      [Y] ) break;;
      [n] ) exit;;
      *  ) echo "Please answer with Y/n ";;
  esac
done

GCS_OUTPUT_PATH=gs://${INTERNAL_BUCKET}/${VERSION}
# Copy contents from most recent private bucket
gsutil cp -r gs://${INTERNAL_BUCKET}/${RELEASE_SHA}/* ${GCS_OUTPUT_PATH}/
# Copy & update contents of internal bucket folder to public-facing bucket version & 'latest' folders
gsutil cp -r ${GCS_OUTPUT_PATH}/* gs://${RELEASE_BUCKET}/${VERSION}/
gsutil cp -r gs://${RELEASE_BUCKET}/${VERSION}/* gs://${RELEASE_BUCKET}/latest/

# Update the GitHub repo
${REPO_ROOT}/google-internal/scripts/update-github.sh --version ${VERSION} --release-sha ${RELEASE_SHA}

# Update Runtime Config with the latest public version
gcloud beta runtime-config configs variables set latest-public-version ${VERSION} \
  --config-name cnrm-eap \
  --project cnrm-eap

# Add annotated git tag to track the release version number & SHA
cd ${REPO_ROOT}
git tag -a "${VERSION}" ${RELEASE_SHA} -m "KCC release version ${VERSION}"
# Reference a placeholder ticket due to new restrictions in Gerrit
git push origin "${VERSION}" -o push-justification='b/299319213'

# Update resource docs
${REPO_ROOT}/google-internal/scripts/release/update-public-docs.sh

# TODO: b/243566783 Re-enable update-gcloud and update oncall
# instructions after b/243566783 is done
# update the config-connector component in gcloud
# ${REPO_ROOT}/google-internal/scripts/update-gcloud.sh --version ${VERSION}