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

while [[ $# -gt 0 ]]; do
  case "${1}" in
    --version)      VERSION="${2:-}"; shift ;;
    --release-sha)  RELEASE_SHA="${2:-}"; shift ;;
    --tag-sha)      TAG_SHA="${2:-}"; shift ;;
    *)              echo "Unrecognized command line parameter: $1"; exit 1 ;;
  esac
  shift
done

# Ensure that the user has run gcert so we can communicate with GoB
prodcertstatus
if [[ $? -gt 0 ]]; then
    echo "ERROR: Please run gcert."
    exit 1
fi

# Check if version, release SHA and tag SHA were given
[[ -z "${VERSION:-}" ]] && { echo "Error: Version not specified"; exit 1; }
[[ -z "${RELEASE_SHA:-}" ]] && { echo "Error: Release SHA not specified"; exit 1; }
[[ -z "${TAG_SHA:-}" ]] && { echo "Error: Tag SHA not specified"; exit 1; }

source "${REPO_ROOT}/google-internal/scripts/shared-vars.sh"

BUCKET=cnrm
RELEASE_DIR=$(mktemp -td update-github.release.XXXXXXXX)
CNRM_DIR=$(mktemp -td update-github.cnrm.XXXXXXXX)
CRD_DIR=$(mktemp -td update-github.crds.XXXXXXXX)
GITHUB_DIR=$(mktemp -td update-github.github.XXXXXXXX)
GITHUB_CRD_DIR=${GITHUB_DIR}/crds
GITHUB_INSTALL_BUNDLES_DIR=${GITHUB_DIR}/install-bundles
GITHUB_VERSION_TAG="v${VERSION}"

gsutil cp -r gs://${BUCKET}/${VERSION}/* ${RELEASE_DIR}
cd ${RELEASE_DIR}
tar zxvf release-bundle.tar.gz

git clone sso://cnrm/cnrm ${CNRM_DIR}
cd ${CNRM_DIR}
git checkout ${RELEASE_SHA}

git clone git@github.com:GoogleCloudPlatform/k8s-config-connector.git ${GITHUB_DIR}
# Substitute occurrences of "github.com/GoogleCloudPlatform/k8s-config-connector" with "github.com/GoogleCloudPlatform/k8s-config-connector" in the import paths.
find ${GITHUB_DIR}/pkg/ -type f -print0 | xargs -0 sed -i 's/cnrm.googlesource.com\/cnrm/github.com\/GoogleCloudPlatform\/k8s-config-connector/g'
export GOFLAGS=-mod=readonly && cd ${GITHUB_DIR} && go vet ./pkg/...

# Prepare CRDs
crds_file=${RELEASE_DIR}/install-bundle-workload-identity/crds.yaml # All install bundles have the same crds.yaml file, so any of them would work
cd ${REPO_ROOT} && go run ${REPO_ROOT}/scripts/parse-crds/parse-crds.go -file ${crds_file} -output-dir ${CRD_DIR}
rm -rf ${GITHUB_CRD_DIR}
mkdir ${GITHUB_CRD_DIR}
for filepath in ${CRD_DIR}/*.yaml; do
    filename=$(basename -- ${filepath})
    ${REPO_ROOT}/google-internal/scripts/add-license-header-to-yaml.sh ${filepath} > ${GITHUB_CRD_DIR}/${filename}
done

cp -rf ${RELEASE_DIR}/install* ${GITHUB_INSTALL_BUNDLES_DIR}

# 1. Update CustomResourceDefinitions under crds/
# 2. Update Cloud Code Snippets under config/cloudcodesnippets/
# 3. Push release and version tag to GitHub
# GitHub tag needs to be formatted as vMAJOR.MINOR.PATCH because Go Modules
# must be semantically versioned
cd ${GITHUB_DIR}
go run ${GITHUB_DIR}/scripts/generate-cloud-code-snippets/generate_snippets.go
changed_file_count=$(git ls-files --modified --other | wc -l)
if [[ ${changed_file_count} -gt 0 ]]; then
    git add -A ${GITHUB_DIR}
    git commit -m "Update for version ${VERSION}"
    git tag -a "${GITHUB_VERSION_TAG}" ${TAG_SHA} -m "KCC release version ${GITHUB_VERSION_TAG}"
    git push origin master
    git push origin ${GITHUB_VERSION_TAG}
fi
