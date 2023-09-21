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

SHORT_SHA="$(git rev-parse --short=7 HEAD)"

BUCKET=kcc-operator-internal
ADDON_BUCKET=kcc-addon-internal
PROJECT_ID=cnrm-eap
OPERATOR_SRC_ROOT="${REPO_ROOT}/operator"
cd ${OPERATOR_SRC_ROOT}
source ./scripts/fetch_ext_bins.sh && \
	fetch_tools && \
	setup_envs

if [[ $debug = false ]] ; then
	gcloud auth activate-service-account --key-file "${GOOGLE_APPLICATION_CREDENTIALS}"
	gcloud auth configure-docker
	gcloud config set core/project ${PROJECT_ID}
fi

if [[ $debug = false ]] ; then
	# Create bucket if it doesn't exist
	if [[ "$(gsutil du -s gs://${BUCKET}/ 2>&1)" == *BucketNotFoundException* ]]; then
	  gsutil mb gs://${BUCKET}/
	fi
fi


# Build images and manifests
KUSTOMIZE="go run -mod=mod sigs.k8s.io/kustomize/kustomize/v5@v5.0.1"
make docker-build
if [[ $debug = false ]] ; then
	make docker-push
	make -C ${REPO_ROOT}/google-internal/operator docker-push-gke
fi
mkdir -p release-bundle/operator-system
${KUSTOMIZE} build config/default > release-bundle/operator-system/configconnector-operator.yaml
${KUSTOMIZE} build config/autopilot > release-bundle/operator-system/autopilot-configconnector-operator.yaml
cp -r config/samples/ release-bundle/
tar -czvf release-bundle.tar.gz -C release-bundle/ .
if [[ $debug = false ]] ; then
	gsutil cp release-bundle.tar.gz gs://${BUCKET}/${SHORT_SHA}/
fi

if [[ $debug = false ]] ; then
	# Run E2E test for release candidate denoted by SHORT_SHA
	${REPO_ROOT}/google-internal/operator/scripts/release-subscripts/e2e-test.sh ${SHORT_SHA}
fi

if [[ $debug = false ]] ; then
	echo "${SHORT_SHA} passed E2E test; promoting it to 'latest' bucket"
	gsutil cp release-bundle.tar.gz gs://${BUCKET}/latest/
fi

# Generate manifests specificlly for GKE addon
mkdir -p cluster-bundle/
${KUSTOMIZE} build config/gke-addon > cluster-bundle/configconnector-operator.yaml
cp config/gke-addon/image_configmap.yaml  cluster-bundle/image_configmap.yaml
if [[ $debug = false ]] ; then
	gsutil cp -r cluster-bundle/ gs://${ADDON_BUCKET}/latest/
fi
