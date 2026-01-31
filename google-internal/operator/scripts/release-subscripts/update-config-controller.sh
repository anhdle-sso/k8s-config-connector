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

REVIEWERS_FLAGGED_COMMA_DELIMITED="r=lmadariaga@google.com,r=xiaoweim@google.com"

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

TEMP_RES_DIR="config-connector-alpha-resources-new"
mkdir -p "${TEMP_RES_DIR}"

echo "Updating alpha resources while preserving existing headers..."

find tmp-kcc-clone/config/crds/resources -type f -name "*.yaml" | while read -r file; do
  if grep -q "v1alpha1" "$file" && ! grep -q "v1beta1" "$file"; then
    # Construct filename based on KCC convention: service_version_kind.yaml
    # We expect standard CRD formatting
    group=$(awk '/^  group:/ {print $2; exit}' "$file")
    kind=$(awk '/^    kind:/ {print $2; exit}' "$file")

    if [ -n "$group" ] && [ -n "$kind" ]; then
      service=$(echo "$group" | cut -d. -f1)
      kind_lower=$(echo "$kind" | tr '[:upper:]' '[:lower:]')
      filename="${service}_v1alpha1_${kind_lower}.yaml"
    else
      # Fallback to source filename if extraction fails
      filename=$(basename "$file")
    fi

    dest_file="containers/bootstrap/assets/config-connector-alpha-resources/${filename}"
    temp_file="${TEMP_RES_DIR}/${filename}"

    if [ -f "${dest_file}" ]; then
      # Keep existing header from dest_file (first contiguous block of comments)
      sed -n '/^#/!q; p' "${dest_file}" > "${temp_file}"
      echo "" >> "${temp_file}"
      # Append body from new file (skipping its header)
      awk '/^[^#]|^$/{f=1} f{print}' "$file" >> "${temp_file}"
    else
      cp "$file" "${temp_file}"
    fi

    # Update the version annotation in the copied file
    sed -i "s/cnrm.cloud.google.com\/version: 0.0.0-dev/cnrm.cloud.google.com\/version: ${VERSION}/g" "${temp_file}"
  fi
done

rm -f containers/bootstrap/assets/config-connector-alpha-resources/*
if [ -n "$(ls -A "${TEMP_RES_DIR}")" ]; then
  mv "${TEMP_RES_DIR}"/* containers/bootstrap/assets/config-connector-alpha-resources/
fi
rmdir "${TEMP_RES_DIR}"

rm -rf tmp-kcc-clone
git add .

# ensure we have the the Change-Id hook installed.
f=$(git rev-parse --git-dir)/hooks/commit-msg ; mkdir -p "$(dirname $f)" ; curl -Lo $f https://gerrit-review.googlesource.com/tools/hooks/commit-msg ; chmod +x $f
git commit -m "Update KCC to $VERSION"
git push -u origin HEAD:refs/for/master%${REVIEWERS_FLAGGED_COMMA_DELIMITED} -o nokeycheck
popd
# After this, check https://acp-review.git.corp.google.com/dashboard/self
# for your CL.
