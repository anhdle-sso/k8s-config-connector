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

ADDON_BUCKET=kcc-addon-internal
OPERATOR_INTERNAL_BUCKET=kcc-operator-internal
OPERATOR_PUBLIC_BUCKET=configconnector-operator
GKE_OPERATOR_IMAGE=gcr.io/gke-release/cnrm/operator
CNRM_EAP_CONTAINER_REGISTRY=gcr.io/cnrm-eap/cnrm/operator

## GKE addon release ###

# Copy contents from most recent private bucket
ADDON_DIR=$(mktemp -d /tmp/addon-release.XXXXXXXX)
gsutil cp -r gs://${ADDON_BUCKET}/latest/* $ADDON_DIR
ADDON_DIR=$ADDON_DIR/cluster-bundle

# Extract the version
VERSION=$(grep -oP -m 1 'cnrm.cloud.google.com/operator-version: \K.+' $ADDON_DIR/configconnector-operator.yaml)

# Extract the short SHA
SHORT_SHA=$(grep -oP -m 1 "${GKE_OPERATOR_IMAGE}:\K.+" $ADDON_DIR/configconnector-operator.yaml)

# Extract the digest
DIGEST=$(gcloud container images describe ${CNRM_EAP_CONTAINER_REGISTRY}:${SHORT_SHA} --format="get(image_summary.digest)")

# Prepare google3 addon clusterbundle submission
CLIENT_NAME=configconnector_addon_$(date +%s)
p4 g4d -f $CLIENT_NAME
GOOGLE3_TARGET_DIR=/google/src/cloud/$USER/$CLIENT_NAME/google3/cloud/kubernetes/distro/components/configconnector

cp -a $ADDON_DIR/. $GOOGLE3_TARGET_DIR/
cd $GOOGLE3_TARGET_DIR
sed -i "s/version: [0-9]\+\.[0-9]\+\.[0-9]\+.*/version: $VERSION/g" kcc-component-builder.yaml
sed -i "/${GKE_OPERATOR_IMAGE//\//\\/}/ s/$/@${DIGEST}/" configconnector-operator.yaml
p4 reopen
p4 change --desc "Updating ConfigConnector clusterbundle to $VERSION

NO_BUG=Upgrading the version of ConfigConnector clusterbundle."

## standalone operator release ##

# Copy contents from most recent private bucket
OPERATOR_DIR=$(mktemp -d /tmp/operator-release.XXXXXXXX)
gsutil cp -r gs://${OPERATOR_INTERNAL_BUCKET}/latest/* $OPERATOR_DIR
tar zxvf $OPERATOR_DIR/release-bundle.tar.gz -C $OPERATOR_DIR
# Extract the version
VERSION=$(grep -oP -m 1 'cnrm.cloud.google.com/operator-version: \K.+' $OPERATOR_DIR/operator-system/configconnector-operator.yaml)

# Copy the latest version to public-facing bucket version & 'latest' folders
echo "releasing version ${VERSION} to public"
gsutil cp -r gs://${OPERATOR_INTERNAL_BUCKET}/latest/* gs://${OPERATOR_PUBLIC_BUCKET}/${VERSION}/
gsutil cp -r gs://${OPERATOR_PUBLIC_BUCKET}/${VERSION}/* gs://${OPERATOR_PUBLIC_BUCKET}/latest/

echo "creating config controller CL"
${REPO_ROOT}/google-internal/operator/scripts/release-subscripts/update-config-controller.sh "$VERSION"
echo "done! check https://acp-review.git.corp.google.com/dashboard/self to find the open CL."