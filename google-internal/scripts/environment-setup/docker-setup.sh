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

sudo apt remove docker-engine docker-runc docker-containerd

set -o errexit

sudo glinux-add-repo docker-ce-"$(lsb_release -cs)"
sudo apt update
sudo apt install docker-ce

sudo service docker stop
sudo ip link set docker0 down
sudo ip link del docker0

cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "data-root": "/usr/local/google/docker",
  "bip": "192.168.9.1/24",
  "default-address-pools": [
    {
      "base": "192.168.11.0/22",
      "size": 24
    }
  ],
  "storage-driver": "overlay2",
  "debug": true,
  "registry-mirrors": ["https://mirror.gcr.io"]
}
EOF

sudo service docker start

# This will set up sudoless docker
set +e
sudo addgroup docker
sudo adduser $USER docker
set -e

GREEN='\033[0;32m'
NC='\033[0m'
echo -e "${GREEN}DOCKER SETUP SUCCESSFUL${NC}"
