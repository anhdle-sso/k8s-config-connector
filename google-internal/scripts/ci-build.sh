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
source "${REPO_ROOT}/google-internal/scripts/shared-vars.sh"
cd ${REPO_ROOT}

# 1. Mock sudo for legacy scripts (like generate-proto.sh)
function mock_sudo() {
  if ! command -v sudo >/dev/null 2>&1; then
    echo -e '#!/bin/bash\n"$@"' > /tmp/sudo
    chmod +x /tmp/sudo
    export PATH="/tmp:$PATH"
  fi
}

# 2. Install older protoc (v22.0) to match the repo's generation date
function install_protoc() {
  PROTOC_VERSION="22.0"
  if ! command -v protoc >/dev/null 2>&1 || [[ "$(protoc --version)" != *"${PROTOC_VERSION}"* ]]; then
    mkdir -p /tmp/protoc_install
    curl -L "https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOC_VERSION}/protoc-${PROTOC_VERSION}-linux-x86_64.zip" -o /tmp/protoc_install/protoc.zip
    unzip -q -o /tmp/protoc_install/protoc.zip -d /tmp/protoc_install
    export PATH="/tmp/protoc_install/bin:$PATH"
  fi
}

# 3. Install latest Go Proto plugins
function install_proto_plugins() {
  go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
  go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
  export PATH="$PATH:$(go env GOPATH)/bin"
}

# 4. Install kustomize (Manual download as a workaround for apt-get)
function install_kustomize() {
  if ! command -v kustomize >/dev/null 2>&1; then
    KUSTOMIZE_VERSION="5.4.3"
    curl -L "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv${KUSTOMIZE_VERSION}/kustomize_v${KUSTOMIZE_VERSION}_$(go env GOOS)_$(go env GOARCH).tar.gz" -o /tmp/kustomize.tar.gz
    tar -xzf /tmp/kustomize.tar.gz -C /tmp
    chmod +x /tmp/kustomize
    export PATH="/tmp:$PATH"
  fi
}

# 5. Setup Go and Test Assets
function setup_test_assets() {
  go mod download
  go install sigs.k8s.io/controller-runtime/tools/setup-envtest@latest

  # Use -p path (not --path) as per setup-envtest usage
  export KUBEBUILDER_ASSETS="$($(go env GOPATH)/bin/setup-envtest use -p path)"

  # Map legacy variables for CNRM script compatibility
  export TEST_ASSET_KUBECTL="$(which kubectl)"
  export TEST_ASSET_KUBE_APISERVER="${KUBEBUILDER_ASSETS}/kube-apiserver"
  export TEST_ASSET_ETCD="${KUBEBUILDER_ASSETS}/etcd"
  export PATH="${KUBEBUILDER_ASSETS}:$PATH"
}

# 6. Run Build
function run_build() {
  ${REPO_ROOT}/scripts/validate-prereqs.sh
  make manager
  make config-connector
  make docker-build
}

mock_sudo
install_protoc
install_proto_plugins
install_kustomize
setup_test_assets
run_build