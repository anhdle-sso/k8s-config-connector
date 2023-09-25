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

CHANGED_FILE_COUNT=$(git diff --name-only | wc -l)
NEW_FILE_COUNT=$(git ls-files --others --exclude-standard | wc -l)
if [[ "${CHANGED_FILE_COUNT}" != "0" ]] || [[ "${NEW_FILE_COUNT}" != "0" ]]; then
    echo "ERROR: Cannot continue rebase with current uncommitted changes."
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

git fetch origin
git switch -C release origin/release


# Pull in changes from main (our github mirror)
git rebase origin/main

# Reference a placeholder ticket due to new restrictions in Gerrit
git push origin HEAD -f -o push-justification='b/299171215'
