#!/usr/bin/env bash

set -e

# sudo chmod +x install_cli_cpu_beta.sh
alltools=false
gpu=false

while getopts 'arh' OPTION; do
  case "$OPTION" in
    a)
      alltools=true
      ;;
    h)
      echo "script usage: $(basename $0) [-a] [-r] [-h]" >&2
      echo "use flag '-a' for installing all tools"
      echo "use flag '-r' for installing only required tools"
      echo "use flag '-g' for installing gpu support tools"
      exit 0
      ;;
    r)
      alltools=false
      ;;
    g)
      gpu=true
      ;;
    ?)
      echo "script usage: $(basename $0) [-a] [-r] [-h]" >&2
      exit 1
      ;;
  esac
done
shift "$(($OPTIND -1))"

sudo mkdir -p /carbonara
cd /carbonara
echo -e "\n"
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo "@     Setting Carbonara Working Directory as '/carbonara'     @"
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo "Downloading Repository ..."
git clone https://github.com/TryCarbonara/NodeInstallation
cd /carbonara/NodeInstallation

echo -e "\n"
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo "@  **Step 0:** Installing pre-requisites for supporting Carbonara Setup  @"
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo "Installing Docker Engine ..."
sudo apt-get update
sudo apt install -y docker.io
sudo apt install -y figlet

echo -e "\n"
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo '@ **Step 1:** Install IPMI exporter tool, for host power consumption data  @'
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo "Installing FreeIPMI tool suite ..."
# FreeIPMI
apt-get update && apt-get install freeipmi-tools -y --no-install-recommends && rm -rf /var/lib/apt/lists/*

echo "Installing IPMI Exporter ..."
# IPMI Exporter
wget https://github.com/prometheus-community/ipmi_exporter/releases/download/v1.6.1/ipmi_exporter-1.6.1.linux-amd64.tar.gz
tar xfvz ipmi_exporter-1.6.1.linux-amd64.tar.gz
rm ipmi_exporter-1.6.1.linux-amd64.tar.gz
./ipmi_exporter-1.6.1.linux-amd64/ipmi_exporter --config.file=ipmi_local.yml &

if [ "$gpu" == true ] ; then
  echo -e "\n"
  echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
  echo '@ **Step 1:** Install DCGM exporter tool, for host **GPU (Nvidia)** power consumption data  @'
  echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
  echo "Installing DCGM GPU Manager ..."
  echo "Current VGA devices:"
  lspci | grep -E 'VGA|Display ' | cut -d" " -f 1 | xargs -i lspci -v -s {}

  sudo apt-get update && sudo apt-get install -y ubuntu-drivers-common && sudo ubuntu-drivers devices \
  && sudo apt -y upgrade && sudo ubuntu-drivers autoinstall

  # set up the CUDA repository GPG key
  sudo curl -fsSL https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-keyring_1.0-1_all.deb -o cuda-keyring_1.0-1_all.deb \
  && sudo dpkg -i cuda-keyring_1.0-1_all.deb \
  && sudo add-apt-repository "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/ /"

  # install GPU Manager
  sudo apt update && sudo apt install -y datacenter-gpu-manager \
  && sudo systemctl enable nvidia-dcgm \
  && sudo systemctl start nvidia-dcgm
  #  && sudo dcgmi discovery -l

  echo "Installing DCGM Exporter ..."
  # IPMI Exporter
  sudo curl -fsSL https://raw.githubusercontent.com/TryCarbonara/NodeInstallation/main/client/dcgm-exporter/dcgm-exporter -o /usr/bin/dcgm-exporter && sudo chmod 755 /usr/bin/dcgm-exporter

  if [ -f "/etc/systemd/system/dcgm_exporter.service" ]; then
    sudo cp /etc/systemd/system/dcgm_exporter.service /etc/systemd/system/dcgm_exporter.service.backup
    echo "Backing up existing dcgm_exporter.service to '/etc/systemd/system/dcgm_exporter.service.backup'"
  fi

  sudo curl -fsSL https://raw.githubusercontent.com/TryCarbonara/NodeInstallation/main/client/dcgm-exporter/dcgm_exporter.service -o /etc/systemd/system/dcgm_exporter.service \
    && sudo mkdir -p /etc/sysconfig \
    && sudo echo 'OPTIONS="--address=:'$dvalue'"' | sudo tee /etc/sysconfig/dcgm_exporter
    && sudo mkdir -p /etc/dcgm-exporter \
    && curl -fsSL https://raw.githubusercontent.com/TryCarbonara/NodeInstallation/main/client/dcgm-exporter/default-counters.csv -o /etc/dcgm-exporter/default-counters.csv \
    && curl -fsSL https://raw.githubusercontent.com/TryCarbonara/NodeInstallation/main/client/dcgm-exporter/dcp-metrics-included.csv -o /etc/dcgm-exporter/dcp-metrics-included.csv \

  sudo systemctl daemon-reload && \
  sudo systemctl start dcgm_exporter && \
  sudo systemctl enable dcgm_exporter
fi

echo -e "\n"
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo '@   **Step 2:** Install node exporter tool, for host resource usage data   @'
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo "Installing Node Exporter ..."
docker run -d \
--net="host" \
--pid="host" \
-v "/:/host:ro,rslave" \
quay.io/prometheus/node-exporter:latest \
--path.rootfs=/host --collector.processes --collector.rapl \
--collector.systemd --collector.tcpstat --collector.cpu.info \
--collector.diskstats.ignored-devices="^(ram|loop|fd)\\\\d+$"

if [ $alltools = true ] ; then
  echo -e "\n"
  echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
  echo "@  **Step 3:** Install hubblo/scaphendre tool, for process level power consumption data using RAPL sensor  @"
  echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
  echo "Adding Inter_RAPL_Common Module to Kernel (>= 5.X.X)"
  # If kernel < 5, apply `modprobe intel_rapl` instead
  modprobe intel_rapl_common

  echo "Installing RAPL Sensor (hubblo/scaphendre) Exporter ..."
  docker run -d -v /sys/class/powercap:/sys/class/powercap -v /proc:/proc -p 8080:8080 -ti hubblo/scaphandre prometheus

  echo -e "\n"
  echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
  echo "@  **Step 4:** Install process exporter tool, for process level resource usage data  @"
  echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
  echo "Installing Process Exporter ..."
  docker run -d --rm -p 9256:9256 --privileged -v /proc:/host/proc -v `pwd`:/config ncabatoff/process-exporter --procfs /host/proc -config.path /config/process.yml
else
  echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
  echo "@  Skipping Optional Tools  @"
  echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
fi

echo -e "\n"
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo "@     **Step 3:** Install Grafana Agent, for enabling metrics push      @"
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
docker run -d \
  -v /tmp/agent:/etc/agent/data \
  --network="host" --privileged \
  --env INSTANCE=$(hostname  -I | cut -f1 -d' ') \
  --env PROVIDER="carbonara" \
  -v `pwd`/demo/agent-demo.yaml:/etc/agent/agent.yaml:ro \
  grafana/agent:v0.32.1 -config.expand-env \
  -config.file /etc/agent/agent.yaml

echo -e "\n"
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo "@    You are all set to start publishing metrics to Carbonara    @"
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
figlet -t -k Happy Carbonara!!
echo -e "\n"
read -t 5 -p "Rebooting machine to apply changes ..."
sudo reboot
