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

while [[ $# -gt 0 ]]; do
  case "${1}" in
    --version)      VERSION="${2:-}"; shift ;;
    --authentication)      AUTHENTICATION="${2:-}"; shift ;;
    *)              break
  esac
  shift
done

REPO_ROOT="$(git rev-parse --show-toplevel)"
source "${REPO_ROOT}/google-internal/scripts/shared-vars.sh"
THIS_SCRIPTS_DIR=$(dirname "${BASH_SOURCE}")
cd "${REPO_ROOT}"

PROJECT_ID=$(gcloud config get-value project)
export CLOUDSDK_CORE_DISABLE_PROMPTS=1

# If a version is passed in by the user, download the version
# contents from the internal CNRM bucket. Otherwise, build and
# deploy the local state of the repo.
LOCAL=''
if [[ -z "${VERSION:-}" ]]; then
  echo 'Version unset; using local repo as source'
  LOCAL='true'
  VERSION="$(git rev-parse --short=7 HEAD)"
fi

TMP_DIR=$(mktemp -d "cnrm-test-${VERSION}.XXXXXX" --tmpdir)
SAMPLES_DIR=config/samples
if [[ -z "${LOCAL}" ]]; then
  TARBALL=release-bundle.tar.gz
  gsutil cp "gs://cnrm-internal/${VERSION}/${TARBALL}" "${TMP_DIR}"
  tar -C "${TMP_DIR}" -xvzf "${TMP_DIR}/${TARBALL}"
  SAMPLES_DIR="${TMP_DIR}/samples"
fi

AUTHENTICATION="${AUTHENTICATION:-"serviceaccountkey"}"

ZONE=us-central1-c
ACCESS_TOKEN=$(gcloud auth print-access-token)
PORT_FORWARD_PID=""

echo 'E2E test walkthrough'
echo '-------------------'

services=(
  artifactregistry.googleapis.com
  compute.googleapis.com
  container.googleapis.com
  iamcredentials.googleapis.com
)

for s in ${services[@]}; do
  echo "Enabling ${s}..."
  gcloud services enable ${s} --project ${PROJECT_ID}
done

echo 'Setting up IAM service-account...'
SA_EMAIL="cnrm-system@${PROJECT_ID}.iam.gserviceaccount.com"
ROLE="roles/owner"
gcloud iam service-accounts create cnrm-system --project ${PROJECT_ID}
gcloud projects add-iam-policy-binding ${PROJECT_ID} --member "serviceAccount:${SA_EMAIL}" --role "${ROLE}"

echo 'Creating a cluster...'
gcloud beta container clusters create e2e-test-${VERSION} --project ${PROJECT_ID} --zone ${ZONE} \
  --num-nodes 6 \
  --release-channel regular \
  --workload-pool="${PROJECT_ID}.svc.id.goog"

function cleanup {
  gcloud container clusters delete "e2e-test-${VERSION}" --project "${PROJECT_ID}" --zone "${ZONE}"

  if [[ -d "${TMP_DIR}" ]]; then
     rm -r "${TMP_DIR}"
  fi
}
trap cleanup EXIT

gcloud container clusters get-credentials e2e-test-${VERSION} --project ${PROJECT_ID} --zone ${ZONE}
kubectl create clusterrolebinding cluster-admin-binding --clusterrole cluster-admin \
  --user "$(gcloud config get-value account)"

if [[ "${AUTHENTICATION}" == "workloadidentity" ]]; then
  echo "Setting up workload identity binding"
  gcloud iam service-accounts add-iam-policy-binding --project "${PROJECT_ID}" \
    --role roles/iam.workloadIdentityUser \
    --member "serviceAccount:${PROJECT_ID}.svc.id.goog[cnrm-system/cnrm-controller-manager]" \
    "${SA_EMAIL}"

  echo 'Deploying installation configuration to cluster...'
  if [[ -n "${LOCAL}" ]] ; then
    make docker-build docker-push deploy
  else
    sed -i "s/\${PROJECT_ID?}/${PROJECT_ID}/" "${TMP_DIR}/install-bundle-workload-identity/0-cnrm-system.yaml"
    kubectl apply -f "${TMP_DIR}/install-bundle-workload-identity/"
  fi
else
  echo "Creating a secret containing service account key"
  gcloud iam service-accounts keys create --iam-account "${SA_EMAIL}" ./key.json
  kubectl create namespace cnrm-system
  kubectl create secret generic gcp-key \
    --from-file ./key.json \
    --namespace cnrm-system
  rm ./key.json

  echo 'Deploying installation configuration to cluster...'
  if [[ -n "${LOCAL}" ]] ; then
    make docker-build docker-push deploy-with-secret-volume
  else
    kubectl apply -f "${TMP_DIR}/install-bundle-gcp-identity/"
  fi
fi

kubectl annotate namespace default \
  "cnrm.cloud.google.com/project-id=${PROJECT_ID}" \
  --overwrite

# Wait for all components to be ready
kubectl wait -n cnrm-system --for=condition=Ready pod -l=cnrm.cloud.google.com/system="true" --timeout 180s

"${THIS_SCRIPTS_DIR}/e2e-resource-lifecycle-check.sh"

echo "creating a sample IAMServiceAccountKey resource and make sure the corresponding secret is also created"
kubectl apply -f "${SAMPLES_DIR}/resources/iamserviceaccountkey/"
COUNT=0
while : ; do
  [[ ("$(kubectl get IAMServiceAccountKey -o yaml)" == *"UpToDate"*) ]] \
   && { echo "IAMServiceAccountKey resource created successfully!"; break; }

  [[ COUNT -ge 60 ]] && { echo 'IAMServiceAccountKey resource failed to create'; exit 1; }

  sleep 1
  ((COUNT+=1))
done

COUNT=0
while : ; do
  if  kubectl get secret iamserviceaccountkey-sample; then
      echo "The corresponding secret created successfully!"; break;
  fi

  [[ COUNT -ge 60 ]] && { echo 'The corresponding secret failed to create'; exit 1; }

  sleep 1
  ((COUNT+=1))
done

echo "ensuring externally-managed fields can be updated out-of-band"
kubectl apply -f "${SAMPLES_DIR}/resources/artifactregistryrepository"
kubectl wait --for=condition=Ready -f "${SAMPLES_DIR}/resources/artifactregistryrepository" --timeout=60s
artifact_repo_name="artifactregistryrepository-sample"
gcloud artifacts repositories update "${artifact_repo_name}" --location "us-west1" --project "${PROJECT_ID}" --description "e2e-updated-description"
# Force a reconciliation by updating then re-applying the YAML
sed 's/value-one/value-e2e/g' "${SAMPLES_DIR}/resources/artifactregistryrepository/artifactregistry_v1beta1_artifactregistryrepository.yaml" > "${TMP_DIR}/resource-update-externally-managed-fields.yaml"
kubectl apply -f "${TMP_DIR}/resource-update-externally-managed-fields.yaml"
# Sleep to wait for KCC to start reconciling the resource.
# TODO(jcanseco): Determine that resource has been reconciled by checking for
# status.observedGeneration == metadata.generation instead now that KCC
# resources support status.observedGeneration.
sleep 30
kubectl wait --for=condition=Ready -f "${TMP_DIR}/resource-update-externally-managed-fields.yaml" --timeout=60s
got="$(kubectl get -f "${TMP_DIR}/resource-update-externally-managed-fields.yaml" -o=jsonpath='{.spec.description}')"
if [[ "$got" != *"e2e-updated-description"* ]]; then
  echo "FAIL: expected externally-managed description field to be updated to match underlying API. got: '$got'"
  exit 1
fi
kubectl delete -f "${TMP_DIR}/resource-update-externally-managed-fields.yaml"

echo "ensuring resources are abandoned when the associated CRD is uninstalled"
kubectl apply -f "${SAMPLES_DIR}/resources/artifactregistryrepository"
COUNT=0
while : ; do
  [[ ("$(kubectl get artifactregistryrepositories.artifactregistry.cnrm.cloud.google.com -o yaml)" == *"UpToDate"*) ]] \
   && { echo "Resource created successfully!"; break; }

  [[ COUNT -ge 60 ]] && { echo 'Resource failed to create'; exit 1; }

  sleep 1
  ((COUNT+=1))
done
artifact_repo_name="artifactregistryrepository-sample"
echo "ensuring the 'gcp' shortname works"
kubectl get gcpartifactregistryrepository ${artifact_repo_name}
kubectl delete crd artifactregistryrepositories.artifactregistry.cnrm.cloud.google.com
COUNT=0
while : ; do
  [[ ("$(kubectl get crd artifactregistryrepositories.artifactregistry.cnrm.cloud.google.com 2>&1)" == *"NotFound"*) ]] \
   && { echo "CRD deleted successfully!"; break; }

  [[ COUNT -ge 60 ]] && { echo 'CRD failed to delete.'; exit 1; }

  sleep 1
  ((COUNT+=1))
done
if [[ ("$(gcloud artifacts repositories describe ${artifact_repo_name} --location us-west1 --project ${PROJECT_ID}  2>&1)" == *"NOT_FOUND"*) ]]; then
    echo "FAIL: expected Artifact Registry Repository ${artifact_repo_name} to be abandoned, but was deleted"
    exit 1
fi

echo "ensuring resources are abandoned even when the uninstallation webhook is misconfigured"
kubectl delete validatingwebhookconfiguration abandon-on-uninstall.cnrm.cloud.google.com
# Have to use a different sample for this test case since the previous test
# case deleted the ArtifactRegistryRepository CRD
kubectl apply -f "${SAMPLES_DIR}/resources/iamserviceaccount/"
COUNT=0
while : ; do
  [[ ("$(kubectl get iamserviceaccounts.iam.cnrm.cloud.google.com -o yaml)" == *"UpToDate"*) ]] \
   && { echo "Resource created successfully!"; break; }

  [[ COUNT -ge 60 ]] && { echo 'Resource failed to create'; exit 1; }

  sleep 1
  ((COUNT+=1))
done
gsa_email="iamserviceaccount-sample@${PROJECT_ID}.iam.gserviceaccount.com"
kubectl delete crd iamserviceaccounts.iam.cnrm.cloud.google.com
COUNT=0
while : ; do
  [[ ("$(kubectl get crd iamserviceaccounts.iam.cnrm.cloud.google.com 2>&1)" == *"NotFound"*) ]] \
   && { echo "CRD deleted successfully!"; break; }

  [[ COUNT -ge 60 ]] && { echo 'CRD failed to delete.'; exit 1; }

  sleep 1
  ((COUNT+=1))
done
if [[ ("$(gcloud iam service-accounts describe ${gsa_email} --project ${PROJECT_ID} 2>&1)" == *"PERMISSION_DENIED"*) ]]; then
    echo "FAIL: expected IAM service account ${gsa_email} to be abandoned, but was deleted"
    exit 1
fi
