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

include ../../operator/Makefile # For the vars, targets are likely broken because of relative paths

SHORT_SHA := $(shell git rev-parse --short=7 HEAD)
GKE_OPERATOR_IMG ?= gcr.io/gke-release/cnrm/operator\:${SHORT_SHA}

# Run against the configured Kubernetes cluster in ~/.kube/config
.PHONY: run
run:
	make -C ${REPO_ROOT}/operator generate fmt vet manifests
	go run cmd/manager/main.go --local-repo="./channels"

# Install CRDs into a cluster
.PHONY: install
install:
	make -C ${REPO_ROOT}/operator manifests
	kustomize build ${REPO_ROOT}/operator/config/crd | kubectl apply -f -

# Uninstall CRDs from a cluster
.PHONY: uninstall
uninstall:
	make -C ${REPO_ROOT}/operator manifests
	kustomize build ${REPO_ROOT}/operator/config/crd | kubectl delete -f -

# Deploy controller in the configured Kubernetes cluster in ~/.kube/config
.PHONY: deploy
deploy:
	make -C ${REPO_ROOT}/operator manifests
	# docker-build, docker-push also required, but not explicit to speed up deploy
	kustomize build ${REPO_ROOT}/operator/config/default | kubectl apply -f -

.PHONY: destroy
destroy:
	make -C ${REPO_ROOT}/operator manifests
	kustomize build ${REPO_ROOT}/operator/config/default | kubectl delete -f -

.PHONY: release
release:
	make -C ${REPO_ROOT}/operator manifests
	kustomize build ${REPO_ROOT}/operator/config/release

# Mount the docker image to gcr.io/gke-release
.PHONY: docker-push-gke
docker-push-gke:
	@echo "updating kustomize image patch file for manager"
	cp ${REPO_ROOT}/operator/config/manager/manager_image_patch_template.yaml ${REPO_ROOT}/operator/config/manager/manager_image_patch.yaml
	sed -i'' -e 's@image: .*@image: '"${GKE_OPERATOR_IMG}"'@' ${REPO_ROOT}/operator/config/manager/manager_image_patch.yaml
	cp -f ${REPO_ROOT}/operator/config/autopilot-manager/manager_image_patch_template.yaml ${REPO_ROOT}/operator/config/autopilot-manager/manager_image_patch.yaml
	sed -i'' -e 's@image: .*@image: '"${GKE_OPERATOR_IMG}"'@' ${REPO_ROOT}/operator/config/autopilot-manager/manager_image_patch.yaml
	docker tag ${OPERATOR_IMG} ${GKE_OPERATOR_IMG}
	docker push ${GKE_OPERATOR_IMG}
