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

include ../Makefile # For the vars, targets are likely broken because of relative paths

REPO_ROOT := $(shell git rev-parse --show-toplevel)

PROJECT_ID := $(shell gcloud config get-value project)
SHORT_SHA := $(shell git rev-parse --short=7 HEAD)
BUILDER_IMG ?= gcr.io/${PROJECT_ID}/builder:${SHORT_SHA}
CONTROLLER_IMG ?= gcr.io/${PROJECT_ID}/controller:${SHORT_SHA}
RECORDER_IMG ?= gcr.io/${PROJECT_ID}/recorder:${SHORT_SHA}
WEBHOOK_IMG ?= gcr.io/${PROJECT_ID}/webhook:${SHORT_SHA}
DELETION_DEFENDER_IMG ?= gcr.io/${PROJECT_ID}/deletiondefender:${SHORT_SHA}
UNMANAGED_DETECTOR_IMG ?= gcr.io/${PROJECT_ID}/unmanageddetector:${SHORT_SHA}

# images to gcr.io/gke-release
GKE_RELEASE_PROJECT_ID := gke-release
GKE_CONTROLLER_IMG ?= gcr.io/${GKE_RELEASE_PROJECT_ID}/cnrm/controller:${SHORT_SHA}
GKE_RECORDER_IMG ?= gcr.io/${GKE_RELEASE_PROJECT_ID}/cnrm/recorder:${SHORT_SHA}
GKE_WEBHOOK_IMG ?= gcr.io/${GKE_RELEASE_PROJECT_ID}/cnrm/webhook:${SHORT_SHA}
GKE_DELETION_DEFENDER_IMG ?= gcr.io/${GKE_RELEASE_PROJECT_ID}/cnrm/deletiondefender:${SHORT_SHA}
GKE_UNMANAGED_DETECTOR_IMG ?= gcr.io/${GKE_RELEASE_PROJECT_ID}/cnrm/unmanageddetector:${SHORT_SHA}

# Use Docker BuildKit when building images to allow usage of 'setcap' in
# multi-stage builds (https://github.com/moby/moby/issues/38132)
DOCKER_BUILD := DOCKER_BUILDKIT=1 docker build

# Namespace to use for make targets intended for testing namespaced-mode.
NAMESPACE := default

ifneq ($(origin KUBECONTEXT), undefined)
CONTEXT_FLAG := --context ${KUBECONTEXT}
endif

# Run presubmit test
.PHONY: presubmit-test
presubmit-test:
	make -C ${REPO_ROOT} generate fmt vet manifests
	./scripts/presubmit-test.sh

# Run all Beta integration tests excluding the flaky ones.
.PHONY: integration-test
integration-test:
	make -C ${REPO_ROOT} generate fmt vet manifests
	./scripts/integration-test.sh

# Run the tracked Beta flaky integration tests.
.PHONY: integration-test-flaky
integration-test-flaky:
	make -C ${REPO_ROOT} generate fmt vet manifests
	./scripts/integration-test-flaky.sh

# Run integration tests for auto-generated resources and other alpha resources.
.PHONY: integration-test-alpha
integration-test-alpha:
	make -C ${REPO_ROOT} generate fmt vet manifests
	./scripts/integration-test-alpha.sh

# Run sample resource tests
.PHONY: samples-test
samples-test:
	make -C ${REPO_ROOT} generate fmt vet manifests
	./scripts/samples-test.sh

# Run flaky sample resource tests
.PHONY: samples-test-flaky
samples-test-flaky:
	make -C ${REPO_ROOT} generate fmt vet manifests
	./scripts/samples-test-flaky.sh

# Run e2e fixtures tests
.PHONY: e2e-fixtures-test
e2e-fixtures-test:
	make -C ${REPO_ROOT} generate fmt vet manifests
	./scripts/e2e-fixtures-test.sh

# package a config-connector release tarball
.PHONY: config-connector-package
config-connector-package:
	make -C ${REPO_ROOT} generate fmt vet
	./scripts/config-connector/package.sh

# deploy, but with all targets required to generate and push a working build
.PHONY: deploy-full
deploy-full:
	make -C ${REPO_ROOT} docker-build docker-push deploy
	true

# Deploy with GCP credentials sourced from the "gcp-key" secret mounted as a volume on the pod
.PHONY: deploy-with-secret-volume
deploy-with-secret-volume:
	make -C ${REPO_ROOT} manifests install
	kustomize build ${REPO_ROOT}/config/installbundle/releases/scopes/cluster/withsecretvolume | kubectl apply -f - ${CONTEXT_FLAG}

# Deploy controller in namespaced mode, authenticating using workload identity
.PHONY: deploy-namespaced
deploy-namespaced:
	make -C ${REPO_ROOT} manifests install
	kustomize build ${REPO_ROOT}/config/installbundle/releases/scopes/namespaced/shared-components | kubectl apply -f - ${CONTEXT_FLAG}
	kustomize build ${REPO_ROOT}config/installbundle/releases/scopes/namespaced/per-namespace-components |\
	 sed -e 's/mynamespace/${NAMESPACE}/g' -e 's/$${PROJECT_ID?}/${PROJECT_ID}/g' -e 's/$${NAMESPACE?}/${NAMESPACE}/g' | kubectl apply -f - ${CONTEXT_FLAG}

.PHONY: destroy
destroy:
	kubectl delete sts -n cnrm-system -l cnrm.cloud.google.com/component=cnrm-controller-manager --wait=true
	kubectl delete crds -l cnrm.cloud.google.com/system=true
	kubectl delete validatingwebhookconfiguration abandon-on-uninstall.cnrm.cloud.google.com --ignore-not-found
	kubectl delete validatingwebhookconfiguration validating-webhook.cnrm.cloud.google.com --ignore-not-found
	kubectl delete mutatingwebhookconfiguration mutating-webhook.cnrm.cloud.google.com --ignore-not-found
	kubectl delete namespace cnrm-system --ignore-not-found
	kubectl delete clusterroles,clusterrolebindings -l cnrm.cloud.google.com/system=true

.PHONY: destroy-namespaced
destroy-namespaced: destroy
	kubectl delete validatingwebhookconfiguration abandon-on-uninstall.${NAMESPACE}.cnrm.cloud.google.com --ignore-not-found
	kustomize build config/installbundle/releases/scopes/namespaced/per-namespace-components | sed -e 's/mynamespace/${NAMESPACE}/g'| kubectl delete --ignore-not-found -f - ${CONTEXT_FLAG}

# Should run all needed commands before any CL is sent out.
.PHONY: ready-cl
ready-cl: manifests resource-docs generate-go-client

# Mount the docker image to gcr.io/gke-release
.PHONY: docker-push-gke
docker-push-gke:
	docker tag ${CONTROLLER_IMG} ${GKE_CONTROLLER_IMG}
	docker push ${GKE_CONTROLLER_IMG}
	docker tag ${RECORDER_IMG} ${GKE_RECORDER_IMG}
	docker push ${GKE_RECORDER_IMG}
	docker tag ${WEBHOOK_IMG} ${GKE_WEBHOOK_IMG}
	docker push ${GKE_WEBHOOK_IMG}
	docker tag ${DELETION_DEFENDER_IMG} ${GKE_DELETION_DEFENDER_IMG}
	docker push ${GKE_DELETION_DEFENDER_IMG}
	docker tag ${UNMANAGED_DETECTOR_IMG} ${GKE_UNMANAGED_DETECTOR_IMG}
	docker push ${GKE_UNMANAGED_DETECTOR_IMG}
