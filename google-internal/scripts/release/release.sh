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

usage() {
	echo "Usage: $0 [ -d ]" 1>&2
}

exit_abnormal() {
	usage
	exit 1
}

debug=false
while getopts d flags
do
	case "${flags}" in
		d)
			debug=true;;
		:)
			exit_abnormal;;
		*)
			exit_abnormal;;
	esac
done

if $debug ; then
	echo "We are in debug mode!";
else
	echo "We are in prod mode!";
fi

THIS_SCRIPTS_DIR=$(dirname "${BASH_SOURCE}")
REPO_ROOT="$(git rev-parse --show-toplevel)"
source "${REPO_ROOT}/google-internal/scripts/shared-vars.sh"
source ${THIS_SCRIPTS_DIR}/version.sh
LICENSING_SCRIPT=${REPO_ROOT}/google-internal/scripts/add-license-header-to-yaml.sh

PROJECT_ID=cnrm-eap

cd ${REPO_ROOT}
source ${REPO_ROOT}/scripts/fetch_ext_bins.sh && \
	fetch_tools && \
	setup_envs

if [[ $debug = false ]] ; then
	gcloud auth activate-service-account --key-file "${GOOGLE_APPLICATION_CREDENTIALS}"
	gcloud auth configure-docker
	gcloud config set core/project ${PROJECT_ID}
fi

if [[ $debug = false ]] ; then
	# Create bucket if it doesn't exist
	if [[ "$(gsutil du -s gs://${INTERNAL_RELEASE_BUCKET}/ 2>&1)" == *BucketNotFoundException* ]]; then
	  gsutil mb gs://${INTERNAL_RELEASE_BUCKET}/
	fi
fi

if [[ $debug = false ]] ; then
	# Create Runtime Config config if it doesn't exist
	if [[ "$(gcloud beta runtime-config configs describe cnrm-eap 2>&1)" == *NOT_FOUND* ]]; then
	  gcloud beta runtime-config configs create cnrm-eap
	fi
fi

# Download kubebuilder
version=1.0.5 # latest stable version
arch=amd64
curl -L -O https://github.com/kubernetes-sigs/kubebuilder/releases/download/v${version}/kubebuilder_${version}_linux_${arch}.tar.gz
tar -zxvf kubebuilder_${version}_linux_${arch}.tar.gz
rm -rf "${REPO_ROOT}/bin/kubebuilder"
mkdir -p "${REPO_ROOT}/bin/kubebuilder"
mv kubebuilder_${version}_linux_${arch} "${REPO_ROOT}/bin/kubebuilder"
export PATH=$PATH:${REPO_ROOT}/bin/kubebuilder/bin


# Build and release the install bundle (manager image + YAML files)
make docker-build
if [[ $debug = false ]] ; then
	make docker-push
	make -C google-internal docker-push-gke
fi

BUNDLE_DIR=release-bundle
mkdir -p ${BUNDLE_DIR}
echo ${VERSION} > ${BUNDLE_DIR}/version

make manifests

# Create temp crds.yaml file
CRDS_FILE=$(mktemp -t crds.XXXXXXXX.yaml)

# Combine CRDs into one file and add a license header
kustomize create
kustomize edit add resource config/crds/resources/*.yaml
$LICENSING_SCRIPT <(kustomize build .) > $CRDS_FILE

# Build the install bundle with the secret volume
GCP_IDENTITY_BUNDLE_DIR=${BUNDLE_DIR}/install-bundle-gcp-identity
mkdir -p ${GCP_IDENTITY_BUNDLE_DIR}
$LICENSING_SCRIPT <(kustomize build config/installbundle/releases/scopes/cluster/withsecretvolume) > ${GCP_IDENTITY_BUNDLE_DIR}/0-cnrm-system.yaml
cp $CRDS_FILE ${GCP_IDENTITY_BUNDLE_DIR}/crds.yaml
sed -i "s/0.0.0-dev/${VERSION}/g" ${GCP_IDENTITY_BUNDLE_DIR}/*
# Create the autopilot variant of the secret volume install bundle
AUTOPILOT_GCP_IDENTITY_BUNDLE_DIR=${BUNDLE_DIR}/install-bundle-autopilot-gcp-identity
mkdir -p ${AUTOPILOT_GCP_IDENTITY_BUNDLE_DIR}
$LICENSING_SCRIPT <(kustomize build config/installbundle/releases/scopes/cluster/autopilot-withsecretvolume) > ${AUTOPILOT_GCP_IDENTITY_BUNDLE_DIR}/0-cnrm-system.yaml
cp $CRDS_FILE ${AUTOPILOT_GCP_IDENTITY_BUNDLE_DIR}/crds.yaml
sed -i "s/0.0.0-dev/${VERSION}/g" ${AUTOPILOT_GCP_IDENTITY_BUNDLE_DIR}/*

# Build the install bundle with workload identity
WORKLOAD_IDENTITY_BUNDLE_DIR=${BUNDLE_DIR}/install-bundle-workload-identity
mkdir -p ${WORKLOAD_IDENTITY_BUNDLE_DIR}
$LICENSING_SCRIPT <(kustomize build config/installbundle/releases/scopes/cluster/withworkloadidentity) > ${WORKLOAD_IDENTITY_BUNDLE_DIR}/0-cnrm-system.yaml
cp $CRDS_FILE ${WORKLOAD_IDENTITY_BUNDLE_DIR}/crds.yaml
sed -i "s/0.0.0-dev/${VERSION}/g" ${WORKLOAD_IDENTITY_BUNDLE_DIR}/*
# Create the autopilot variant of the workload identity install bundle
AUTOPILOT_WORKLOAD_IDENTITY_BUNDLE_DIR=${BUNDLE_DIR}/install-bundle-autopilot-workload-identity
mkdir -p ${AUTOPILOT_WORKLOAD_IDENTITY_BUNDLE_DIR}
$LICENSING_SCRIPT <(kustomize build config/installbundle/releases/scopes/cluster/autopilot-withworkloadidentity) > ${AUTOPILOT_WORKLOAD_IDENTITY_BUNDLE_DIR}/0-cnrm-system.yaml
cp $CRDS_FILE ${AUTOPILOT_WORKLOAD_IDENTITY_BUNDLE_DIR}/crds.yaml
sed -i "s/0.0.0-dev/${VERSION}/g" ${AUTOPILOT_WORKLOAD_IDENTITY_BUNDLE_DIR}/*

# Build the namespaced-mode install bundle (uses workload identity)
NAMESPACED_BUNDLE_DIR=${BUNDLE_DIR}/install-bundle-namespaced
mkdir -p ${NAMESPACED_BUNDLE_DIR}
$LICENSING_SCRIPT <(kustomize build config/installbundle/releases/scopes/namespaced/shared-components) > ${NAMESPACED_BUNDLE_DIR}/0-cnrm-system.yaml
$LICENSING_SCRIPT <(kustomize build config/installbundle/releases/scopes/namespaced/per-namespace-components) |\
  sed -e 's/mynamespace/${NAMESPACE?}/g' > ${NAMESPACED_BUNDLE_DIR}/per-namespace-components.yaml
cp $CRDS_FILE ${NAMESPACED_BUNDLE_DIR}/crds.yaml
sed -i "s/0.0.0-dev/${VERSION}/g" ${NAMESPACED_BUNDLE_DIR}/*
# Create the autopilot variant of the namespaced-mode install bundle
AUTOPILOT_NAMESPACED_BUNDLE_DIR=${BUNDLE_DIR}/install-bundle-autopilot-namespaced
mkdir -p ${AUTOPILOT_NAMESPACED_BUNDLE_DIR}
$LICENSING_SCRIPT <(kustomize build config/installbundle/releases/scopes/namespaced/autopilot-shared-components) > ${AUTOPILOT_NAMESPACED_BUNDLE_DIR}/0-cnrm-system.yaml
$LICENSING_SCRIPT <(kustomize build config/installbundle/releases/scopes/namespaced/per-namespace-components) |\
  sed -e 's/mynamespace/${NAMESPACE?}/g' > ${AUTOPILOT_NAMESPACED_BUNDLE_DIR}/per-namespace-components.yaml
cp $CRDS_FILE ${AUTOPILOT_NAMESPACED_BUNDLE_DIR}/crds.yaml
sed -i "s/0.0.0-dev/${VERSION}/g" ${AUTOPILOT_NAMESPACED_BUNDLE_DIR}/*

# Add the sample YAML files and applications to tarball
cp -r config/samples/ ${BUNDLE_DIR}/

tar -czvf release-bundle.tar.gz -C ${BUNDLE_DIR}/ .
if [[ $debug = false ]] ; then
	gsutil cp release-bundle.tar.gz ${GCS_SHA_DEST}/
	gsutil cp release-bundle.tar.gz ${GCS_LATEST_DEST}/
fi

if [[ $debug = false ]] ; then
	# Create the config-connector binary release and run its end to end tests.
	${REPO_ROOT}/google-internal/scripts/config-connector/release.sh

	# Run e2e, integration, and samples tests
	echo "Running the e2e test with 'serviceaccountkey' authentication..."
	${REPO_ROOT}/google-internal/scripts/config-connector/e2e-test-new-env.sh --version ${SHORT_SHA} --authentication "serviceaccountkey"

	echo "Running the e2e test with 'workloadidentity' authentication..."
	${REPO_ROOT}/google-internal/scripts/config-connector/e2e-test-new-env.sh --version ${SHORT_SHA} --authentication "workloadidentity"

	# Update Runtime Config with the latest SHA version
	gcloud beta runtime-config configs variables set latest-version ${SHORT_SHA} \
	  --config-name cnrm-eap
fi
