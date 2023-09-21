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


# This script exists to allow us to run cleanup-leaked-test-resources.sh via
# Prow, specifically via the `periodic-cnrm-cleanup` job whose configuration
# can be found at
# https://gke-internal.googlesource.com/test-infra/+/refs/heads/master/prow/gob/config/cnrm-review.googlesource.com/cnrm/cnrm-cnrm.yaml

set -o errexit
set -o nounset
set -o pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
source "${REPO_ROOT}/google-internal/scripts/shared-vars.sh"
cd ${REPO_ROOT}

echo "Activating service-account in gcloud..."
gcloud auth activate-service-account --key-file=${GOOGLE_APPLICATION_CREDENTIALS}

${REPO_ROOT}/google-internal/scripts/cleanup-leaked-test-resources.sh