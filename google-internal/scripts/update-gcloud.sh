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
    --version)      VERSION="${2:-}"; shift ;;
    *)              echo "Unrecognized command line parameter: $1"; exit 1 ;;
  esac
  shift
done

# Ensure that we have access to prod
prodcertstatus
if [[ $? -gt 0 ]]; then
    echo "ERROR: run 'gcert' to refresh your credentials"
    exit 1
fi

# Ensure the version was given
[[ -z "${VERSION:-}" ]] && { echo "ERROR: version not specified, use the --version parameter"; exit 1; }

TMP_DIR=$(mktemp -d)
pushd ${TMP_DIR}
gsutil cp gs://${RELEASE_BUCKET}/${VERSION}/${CLI_TARBALL_NAME} .
tar zxf ${CLI_TARBALL_NAME}

for os in $(find . -maxdepth 1 -type d ! -name '.*' -printf '%f\n'); do
  for arch in $(find ${os}/. -maxdepth 1 -type d ! -name '.*' -printf '%f\n'); do
    echo Building tarball for ${os}/${arch}
    # To be compatible with gcloud / google3 tooling, the tarball must contain no
    # directories or paths and only the 'config-connector' binary. To accomplish
    # this, change to the directory and tar the only file in the directory (the
    # -C flag does not accomplish this)
    pushd ${os}/${arch}
    # Renaming because linux_aarch64 is the format that gcloud recognizes for
    # ARM on linux
    if [[ "$os" == "linux" && "$arch" == "arm64" ]]; then
        arch="aarch64"
    fi
    tar zcf ../../config-connector_${os}_${arch}-${VERSION}.tar.gz *
    popd
  done
done

CLIENT_NAME=configconnector_cli_$(date +%s)
p4 g4d -f ${CLIENT_NAME}
CLIENT_ROOT=/google/src/cloud/$(whoami)/${CLIENT_NAME}
TARBALL_TARGET_DIR=${CLIENT_ROOT}/google3/third_party/cloudsdk/component_build/cloud_tools

# Delete tarballs for the previous version
rm -f ${TARBALL_TARGET_DIR}/config-connector*.tar.gz

for t in $(ls config-connector*.tar.gz); do
  echo "Copying ${t} to google3..."
  cp ${t} ${TARBALL_TARGET_DIR}
done
popd

# Update the SDK release notes, see: go/cloud-sdk-release-notes
echo "* Updated Google Cloud Config Connector to version ${VERSION}.
  See Config Connector Overview for more details [https://cloud.google.com/config-connector/docs/overview](https://cloud.google.com/config-connector/docs/overview)." > ${CLIENT_ROOT}/google3/cloud/sdk/component_build/release_notes/Config_Connector.md

buildozer "set version ${VERSION}" ${CLIENT_ROOT}/google3/cloud/sdk/release:config-connector

#pushd ${TARBALL_TARGET_DIR}
pushd ${CLIENT_ROOT}/google3
p4 reopen
MSG=$(p4 diffstats 2>&1)
if [[ ${MSG} =~ "File(s) not opened on this client" ]]; then
    echo "no changes for config-connector"
    p4 citc -d ${G4_CLIENT_NAME}
else
  p4 change --desc "Updating config-connector gcloud component binaries to ${VERSION}" -m ibelle,nathanlooney,kcc-eng
fi
