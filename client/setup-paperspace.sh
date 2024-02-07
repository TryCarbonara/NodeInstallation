#!/usr/bin/env bash

sudo apt-get update && sudo apt-get install -y ubuntu-drivers-common && sudo ubuntu-drivers devices \
        && sudo apt-get install -y nvidia-driver-535 && sudo apt-get install -y docker.io && sudo reboot

# https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
  && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl daemon-reload && sudo systemctl restart docker

#wget -q -O - https://raw.githubusercontent.com/TryCarbonara/NodeInstallation/main/client/install_cli_agent.sh  | bash -s -- -u 'carbonara' -p 'carbonara' -r 'something.com' -t 9090 -g

# pyroscope
sudo docker pull grafana/pyroscope:latest
sudo docker network create pyroscope-demo
sudo docker run -d --restart=always --name=pyroscope --network=pyroscope-demo -p 4040:4040 grafana/pyroscope:latest
sudo docker run -d --restart=always --name=grafana -p 3000:3000 -e "GF_FEATURE_TOGGLES_ENABLE=flameGraph" --network=pyroscope-demo grafana/grafana:main

sudo mkdir -p /carbonara/prom
sudo docker run \
  -d --restart=always \
  -p 9090:9090 \
  -v /carbonara/prom/prometheus.yml:/etc/prometheus/prometheus.yml \
  prom/prometheus

sudo docker run -d \
  --restart=always \
  --net="host" \
  --pid="host" \
  -v "/:/host:ro,rslave" \
  quay.io/prometheus/node-exporter:latest \
  --path.rootfs=/host

sudo docker run -d \
  --name nvidia_smi_exporter \
  --restart unless-stopped \
  --device /dev/nvidiactl:/dev/nvidiactl \
  --device /dev/nvidia0:/dev/nvidia0 \
  -v /usr/lib/x86_64-linux-gnu/libnvidia-ml.so:/usr/lib/x86_64-linux-gnu/libnvidia-ml.so \
  -v /usr/lib/x86_64-linux-gnu/libnvidia-ml.so.1:/usr/lib/x86_64-linux-gnu/libnvidia-ml.so.1 \
  -v /usr/bin/nvidia-smi:/usr/bin/nvidia-smi \
  -p 9835:9835 \
  utkuozdemir/nvidia_gpu_exporter:1.1.0

sudo apt-get install -y python3-docker --no-install-recommends --no-upgrade
VERSION=v0.36.0 # use the latest release version from https://github.com/google/cadvisor/releases
sudo docker run \
  --volume=/:/rootfs:ro \
  --volume=/var/run:/var/run:ro \
  --volume=/sys:/sys:ro \
  --volume=/var/lib/docker/:/var/lib/docker:ro \
  --volume=/dev/disk/:/dev/disk:ro \
  --publish=8080:8080 \
  --detach=true \
  --name=cadvisor \
  --privileged \
  --device=/dev/kmsg \
  --restart=always \
  gcr.io/cadvisor/cadvisor:$VERSION

sudo apt install -y python3-pip
pip3 install nvprof


# Jobs ==============================

git clone https://github.com/NVIDIA/DeepLearningExamples.git
cd DeepLearningExamples/PyTorch/LanguageModeling/BERT