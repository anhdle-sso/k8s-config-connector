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

GOOS=$(go env GOOS)
GOARCH=$(go env GOARCH)
CMD_PATH=./${BIN_DIR}/${CONFIG_CONNECTOR_BINARY_NAME}/${GOOS}/${GOARCH}/${CONFIG_CONNECTOR_BINARY_NAME}

TOPIC_NAME=e2e-test-${CONFIG_CONNECTOR_BINARY_NAME}
APPLY_TEST_FIXTURE="${CONFIG_CONNECTOR_BINARY_NAME}_fixture.yaml"
APPLY_TOPIC_NAME=e2e-test-apply-${CONFIG_CONNECTOR_BINARY_NAME}
function cleanup {
  echo "Performing cleanup..."
  if gcloud pubsub topics describe ${TOPIC_NAME}; then
    echo "Deleting topics..."
    gcloud pubsub topics delete ${TOPIC_NAME}
  fi
  gcloud pubsub topics delete "${APPLY_TOPIC_NAME}" --project "${PROJECT_ID}"
  rm ${APPLY_TEST_FIXTURE}
}
trap cleanup EXIT

# create a test pubsub topic resource
echo "Enabling the pubsub service..."
gcloud services enable pubsub.googleapis.com
echo "Creating topic..."
gcloud pubsub topics create ${TOPIC_NAME}
# get the full one platform resource name
TOPIC_RESOURCE_NAME=$(gcloud pubsub topics describe ${TOPIC_NAME} --format "value(name)")
TOPIC_URI="//pubsub.googleapis.com/${TOPIC_RESOURCE_NAME}"
TOPIC_ASSET='{"name":"'"${TOPIC_URI}"'","asset_type":"pubsub.googleapis.com/Topic"}'
# verify that the topic can be exported to YAML
echo "Exporting topic via bulk-export..."
echo ${TOPIC_ASSET} | ${CMD_PATH} bulk-export
# the output of the above command does not include a final newline so insert one so subsequent lines of the script will
# not be in the same output.
echo ""
echo "Exporting topic via export..."
${CMD_PATH} export ${TOPIC_URI}
# see comment above for newline
echo ""

# apply tests
PROJECT_ID=$(gcloud config get-value project)

tee "${APPLY_TEST_FIXTURE}" <<EOF
apiVersion: pubsub.cnrm.cloud.google.com/v1beta1
kind: PubSubTopic
metadata:
    annotations:
        cnrm.cloud.google.com/force-destroy: "false"
        cnrm.cloud.google.com/project-id: ${PROJECT_ID}
    labels:
        label1: e2etest
    name: ${APPLY_TOPIC_NAME}
EOF

${CMD_PATH} apply -i=${APPLY_TEST_FIXTURE}

if [[ ("$(gcloud pubsub topics describe ${APPLY_TOPIC_NAME} --project ${PROJECT_ID} 2>&1)" == *"NOT_FOUND"*) ]]; then
    echo "FAIL: Pub/Sub topic ${APPLY_TOPIC_NAME} not found."
    exit 1
fi