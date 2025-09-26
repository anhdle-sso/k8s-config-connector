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

# updates the Config Controller bundle to the most recent version of
# the KCC operator.
# Example: https://acp-review.git.corp.google.com/c/acp/+/10762/1
set -o nounset
set -o pipefail

REVIEWERS_FLAGGED_COMMA_DELIMITED="r=wfender@google.com,r=yuwenma@google.com,r=xiaoweim@google.com"

TEMP_DIR=$(mktemp -td update-config-controller.cnrm-operator.XXXXXXXX)
# rf is very risky, but git repos write protected files.
trap "rm -rf $TEMP_DIR" EXIT

VERSION="$1"
pushd .
cd "${TEMP_DIR}"
git clone sso://acp/acp
cd acp

# Update KCC operator
KCC_VERSION="${VERSION}" make -C containers/bootstrap/assets/configconnector-operator update
git add .

# Update KCC Alpha Resources Experimental Feature
git clone https://github.com/GoogleCloudPlatform/k8s-config-connector tmp-kcc-clone
cd tmp-kcc-clone
git checkout "v${VERSION}"
cd ..
rm containers/bootstrap/assets/config-connector-alpha-resources/*
cp tmp-kcc-clone/crds/*v1alpha1*.yaml containers/bootstrap/assets/config-connector-alpha-resources/
rm -rf tmp-kcc-clone
git add .

# ensure we have the the Change-Id hook installed.
f=$(git rev-parse --git-dir)/hooks/commit-msg ; mkdir -p "$(dirname $f)" ; curl -Lo $f https://gerrit-review.googlesource.com/tools/hooks/commit-msg ; chmod +x $f
git commit -m "Update KCC to $VERSION"
git push -u origin HEAD:refs/for/master%${REVIEWERS_FLAGGED_COMMA_DELIMITED} -o nokeycheck
popd
# After this, check https://acp-review.git.corp.google.com/dashboard/self
# for your CL.
