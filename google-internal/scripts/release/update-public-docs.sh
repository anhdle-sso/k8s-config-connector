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

# This script updates files used for our public docs
# at https://source.corp.google.com/piper///depot/google3/googledata/devsite/site-cloud/en/config-connector

set -o errexit
set -o nounset
set -o pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
source "${REPO_ROOT}/google-internal/scripts/shared-vars.sh"
THIS_SCRIPTS_DIR=$(dirname "${BASH_SOURCE}")

# Prepare google3 docs submission
cd $REPO_ROOT
CLIENT_NAME=configconnector_resource_doc_$(date +%s)
p4 g4d -f $CLIENT_NAME
GOOGLE3_DOCS_DIR=/google/src/cloud/$USER/$CLIENT_NAME/google3/third_party/devsite/cloud/en/config-connector/docs
# Resource reference docs
cp -r ${REPO_ROOT}/scripts/generate-google3-docs/resource-reference/generated/resource-docs ${GOOGLE3_DOCS_DIR}/reference/
cp -f ${REPO_ROOT}/scripts/generate-google3-docs/resource-reference/_toc.yaml ${GOOGLE3_DOCS_DIR}/reference/
cp -f ${REPO_ROOT}/scripts/generate-google3-docs/resource-reference/overview.md ${GOOGLE3_DOCS_DIR}/reference/
# Resource lists used by google3 docs
cp -f ${REPO_ROOT}/scripts/generate-google3-docs/resource-lists/generated/* ${GOOGLE3_DOCS_DIR}/how-to/
cd ${GOOGLE3_DOCS_DIR}
p4 reopen
MSG=$(p4 diffstats 2>&1)
if [[ ${MSG} =~ "File(s) not opened on this client" ]]; then
    echo "No changes to resource docs"
    p4 citc -d $CLIENT_NAME
else
  p4 change --desc "Updating resource docs

BRANDING_VIOLATION_REASON=Auto-generated descriptions
DISABLE_DISRESPECTFUL_TERMS=Auto-generated descriptions
DISABLE_PRIVATE_KEY_CHECK=Test keys used for example purposes only
DISABLE_HEADING_QUOTES_CHECK=Test cannot distinguish Markdown headers and comments in YAML snippets
"
fi