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

function jreport {
  if [[ -z "${ARTIFACTS}" ]]; then
    echo "${ARTIFACTS} env var is missing, JUnit report will not be generated"
    return
  fi

  cp test_*.txt ${ARTIFACTS}/

  cat test_sample_log1.txt | ${REPO_ROOT}/hack/convert-to-junit-report > ${ARTIFACTS}/junit_sample_report1.xml
}

trap jreport EXIT

set -o errexit
set -o nounset
set -o pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
source "${REPO_ROOT}/google-internal/scripts/shared-vars.sh"
cd ${REPO_ROOT}

${REPO_ROOT}/google-internal/scripts/run-command-new-env.sh \
  --command "${REPO_ROOT}/google-internal/scripts/run-tests-fresh-environment.sh \
  --target-directory './config/tests/samples/...' \
  --skip-tests '${FLAKY_SAMPLES_TESTS_REGEX}'\
  --go-test-timeout '240m'\
  " 2>&1 | tee test_sample_log1.txt
