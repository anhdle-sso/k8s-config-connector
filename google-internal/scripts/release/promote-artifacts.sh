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


set -e
set -x

if [[ -z "${VERSION:-}" ]]; then
  echo "VERSION is required"
  exit 1
fi

if [[ -z "${SRC_TAG:-}" ]]; then
  echo "SRC_TAG is required"
  exit 1
fi

CITC_CLIENT=release_kcc_images_${VERSION//./_}
cd $(p4 g4d -f ${CITC_CLIENT})

# Build convert-kpromo-to-legacy tool from HEAD
blaze build //experimental/users/justinsb/kcc-automation/cmd/convert-kpromo-to-legacy
CONVERT_KPROMO_TO_LEGACY=$(p4 g4d)/blaze-bin/experimental/users/justinsb/kcc-automation/cmd/convert-kpromo-to-legacy/convert-kpromo-to-legacy

MANIFEST="cloud/kubernetes/releng/registry_promoter/manifest/kcc.yaml"

# Open the manifest for editing in Perforce.
p4 edit "${MANIFEST}"

# Generate new image data into a temporary file
TMP_IMAGES_UNSORTED=$(mktemp)
go run sigs.k8s.io/promo-tools/v4/cmd/kpromo@latest cip --snapshot gcr.io/gke-release-staging/cnrm --snapshot-tag ${SRC_TAG} \
  | ${CONVERT_KPROMO_TO_LEGACY} --version=${VERSION} --prefix=cnrm/ > "${TMP_IMAGES_UNSORTED}"

# The new output format is a YAML map and appears to be pre-sorted,
# so the complex sorting logic is no longer needed.
# We will now directly append the generated data to the manifest header.
TMP_MANIFEST=$(mktemp)

# Safely extract the header (up to and including 'images:') to the new manifest file
sed '/^images:/q' "${MANIFEST}" > "${TMP_MANIFEST}"

# Append the new image data from the temp file.
{
  cat "${TMP_IMAGES_UNSORTED}"
} >> "${TMP_MANIFEST}"

# Atomically replace the old manifest with the new one
mv "${TMP_MANIFEST}" "${MANIFEST}"

# Remove a trailing blank line from the manifest, if one exists.
sed -i '$ {/^[[:space:]]*$/d;}' "${MANIFEST}"

# Clean up
rm "${TMP_IMAGES_UNSORTED}"

p4 change --desc "Promote KCC version ${VERSION}"
p4 submit