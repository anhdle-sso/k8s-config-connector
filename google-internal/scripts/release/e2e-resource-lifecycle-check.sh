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

# e2e-resource-lifecycle-check validates that the creation, mutation, and deletion workflow
# for a resource works as intended.

SAMPLES_DIR=config/samples
TMP_DIR=$(mktemp -d "cnrm-test-${VERSION}.XXXXXX" --tmpdir)

function cleanup {
  if [[ -n "${PORT_FORWARD_PID}" ]]; then
     kill -9 "${PORT_FORWARD_PID}"
  fi
  if [[ -d "${TMP_DIR}" ]]; then
     rm -r "${TMP_DIR}"
  fi
}
trap cleanup EXIT

# NOTE: this validation logic must use a sample with the following attributes:
# - no usage of environment variables (${PROJECT_ID?}, ${GSA_EMAIL?}, etc)
# - no dependencies
EXAMPLE_RESOURCE=$(find "${SAMPLES_DIR}/resources/artifactregistryrepository" -name "*artifactregistryrepository.yaml")
echo 'Spinning up resource (ArtifactRegistryRepository)...'
kubectl apply -f "${EXAMPLE_RESOURCE}"

COUNT=0
while : ; do
  [[ ("$(kubectl get artifactregistryrepositories.artifactregistry.cnrm.cloud.google.com -o yaml)" == *"UpToDate"*) ]] \
   && { echo "Resource created successfully!"; break; }

  [[ COUNT -ge 60 ]] && { echo 'Resource failed to create'; kubectl get artifactregistryrepositories.artifactregistry.cnrm.cloud.google.com -o yaml; exit 1; }

  sleep 1
  ((COUNT+=1))
done

echo 'Curling prometheus metrics port...'
kubectl port-forward svc/cnrm-manager 8888:8888 -n cnrm-system &
PORT_FORWARD_PID=$!
function cleanup {
  if [[ -n "${PORT_FORWARD_PID}" ]]; then
     kill -9 ${PORT_FORWARD_PID}
  fi
}
trap cleanup EXIT

sleep 10 # wait some time for port forwording to establish
RESPONSE=$(curl localhost:8888/metrics)
if echo "${RESPONSE}" | grep -q 'configconnector_reconcile_requests_total' ; then
  echo "prometheus metrics have been exported successfully"
else
  echo "FAIL: prometheus metrics cannot be scraped: ${RESPONSE}";
  exit 1;
fi

echo 'trying to apply changes to immutable field(s); expect admission controller to deny the request'
sed 's/format: DOCKER/format: MAVEN/' "${EXAMPLE_RESOURCE}" > "${TMP_DIR}/resource_update_immutable_field.yaml"
MSG="$(kubectl apply -f "${TMP_DIR}/resource_update_immutable_field.yaml" 2>&1 || true)"
if echo "${MSG}" | grep -q 'cannot make changes to immutable field(s)' ; then
  echo "webhook successfully denied the change on immutable fields"
else
  echo "FAIL: webhook failed to deny the change on immutable fields: ${MSG}";
  exit 1;
fi

# TODO(b/193745253): uncomment the following block of code once the bug is fixed.
#echo 'trying to add unknown field(s); expect admission controller to deny the request'
#cp "${EXAMPLE_RESOURCE}" "${TMP_DIR}/resource_update_unknown_field.yaml"
#echo '
#  foo: bar' >> "${TMP_DIR}/resource_update_unknown_field.yaml"
#cat "${TMP_DIR}/resource_update_unknown_field.yaml"
#MSG="$(kubectl apply -f "${TMP_DIR}/resource_update_unknown_field.yaml" 2>&1 || true)"
#if echo "${MSG}" | grep -q 'unknown field' ; then
#  echo "webhook successfully denied the addition of an unknown field"
#else
#  echo "FAIL: webhook failed to deny the addition of an unknown field: ${MSG}";
#  exit 1;
#fi

echo 'Deleting resource (ArtifactRegistryRepository)...'
kubectl delete -f "${EXAMPLE_RESOURCE}"
