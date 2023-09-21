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

set -o errexit
set -o nounset
set -o pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
source "${REPO_ROOT}/google-internal/scripts/shared-vars.sh"
cd ${REPO_ROOT}

export VERSION=${VERSION:-${SHORT_SHA}}
# create the config-connector release and package it, the packager uses the ${VERSION} variable to set the version in the config-connector application binary
make -C ${REPO_ROOT}/google-internal config-connector-package
# run the end-to-end test on the current build
${REPO_ROOT}/google-internal/scripts/config-connector/e2e-test-new-env.sh
# copy the packaged tarball to GCS
gsutil cp ${CLI_TARBALL_BUILD_PATH} ${GCS_SHA_DEST}/
gsutil cp ${CLI_TARBALL_BUILD_PATH} ${GCS_LATEST_DEST}/
