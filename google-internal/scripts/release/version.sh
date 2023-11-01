#!/usr/bin/env bash
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

# this command finds the next valid version, a version is considered valid if there is no git tag with the same name

# this loop finds the next available version id, a version is available if there is no associated git tag
TENTATIVE_NEXT_VERSION=1.112.0

while git rev-parse ${TENTATIVE_NEXT_VERSION} &> /dev/null
do
  TENTATIVE_NEXT_VERSION=$(echo ${TENTATIVE_NEXT_VERSION} | awk -F. -v OFS=. 'NF==1{print ++$NF}; NF>1{$NF=sprintf("%0*d", length($NF), ($NF+1)); print}')
done

export VERSION=${TENTATIVE_NEXT_VERSION}
echo "Version set to ${VERSION}."
