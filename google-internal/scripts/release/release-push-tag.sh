#!/bin/bash
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

#!/bin/bash

# Check if version is set
if [ -z "$version" ]; then
    echo "Error: version must be set"
    exit 1
fi

echo "Version: $version"

# Check if GitOrigin-RevId parameter is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <GitOrigin-RevId>"
    exit 1
fi

git_origin_rev_id=$1

# Search for the commit SHA using git log
commit_sha=$(git log --grep="GitOrigin-RevId: $git_origin_rev_id" --format="%H" | head -n 1)

if [ -n "$commit_sha" ]; then
    echo "Found commit SHA: $commit_sha"
else
    echo "No commit found with GitOrigin-RevId: $git_origin_rev_id"
    exit 1
fi

# Checkout to the commit and create a new branch for the release version
git checkout $commit_sha
git checkout -b push_tag_${version}


repo_root="$(git rev-parse --show-toplevel)"
cd ${repo_root}
go run . --remote sso://cnrm/cnrm  --branch push_tag_${version} --version-file version/VERSION  --source ${repo_root} -v=2  --push-options push-justification=b/382575614
    
# Ask for user confirmation
read -p "Does the result look good? (y/n): " answer

if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
    echo "Proceeding with the command..."
    go run . --remote sso://cnrm/cnrm \
            --branch "push_tag_${VERSION}" \
            --version-file version/VERSION \
            --source "${repo_root}" \
            -v=2 \
            --push-options push-justification=b/382575614 \
            --yes=1
    echo "Successfully executed the command."
else
    echo "Failed to push tag."
    exit 0
fi