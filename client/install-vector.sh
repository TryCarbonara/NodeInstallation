#!/usr/bin/env bash

# [sudo] creating user and user-group
echo "Setting up carbonara user to setup exporters (requires sudo access) ..."
sudo useradd -m carbonara || true
# set password, in case need to ssh directly
# sudo passwd carbonara

# [sudo] pre-requisite:
# # installing free-ipmi
# # # FreeIPMI
if [ -x "$(command -v ipmi-dcmi)" ] ; then
  echo "Skipping FreeIPMI Suite (already exists)!"
  echo "Enabling RAPL module instead, for supported Architecture"
  sudo modprobe intel_rapl_common || true
else
  ""
  # enable ipmi if underlying h/w & kernel supports it
  echo "Installing FreeIPMI Suite (requires sudo access) ..."
  sudo modprobe ipmi_devintf || true
  sudo modprobe ipmi_si || true
  sudo apt-get update && sudo apt-get install freeipmi-tools -y --no-install-recommends --quiet --no-upgrade
fi
# # installing DCGM
if [ -x "$(command -v nvidia-smi)" ] ; then
  if [ -x "$(command -v dcgmi)" ] ; then
    echo "Skipping DCGM Suite (already exists)!"
  else
    echo "Installing DCGM Suite (requires sudo access) ..."
    release=$(echo "ubuntu$(lsb_release -r | awk '{print $2}' | tr -d .)")
    curl -fsSL https://developer.download.nvidia.com/compute/cuda/repos/$release/x86_64/cuda-keyring_1.0-1_all.deb -o cuda-keyring_1.0-1_all.deb \
      && sudo dpkg -i cuda-keyring_1.0-1_all.deb \
      && sudo add-apt-repository -y "deb https://developer.download.nvidia.com/compute/cuda/repos/$release/x86_64/ /"

    sudo apt-get update && sudo apt install -y datacenter-gpu-manager --no-install-recommends --quiet --no-upgrade
    sudo systemctl daemon-reload \
      && sudo systemctl enable nvidia-dcgm \
      && sudo systemctl restart nvidia-dcgm
  fi
else
  echo "Err: Skipping DCGM Suite (GPU driver not found)!"
  exit 1
fi

# # updating apt-get package indexes list
# Setting up the exporters
echo "Running Carbonara script to configure exporters ..."
sudo apt-get update \
  && sudo apt-get install -y curl tar wget \
  && su carbonara -c "wget -q -O - https://raw.githubusercontent.com/TryCarbonara/NodeInstallation/main/client/install_cli_ubuntu-vector.sh | bash -s -- -u $0 -p $1 -r $2"
# enable service lingering for user
sudo loginctl enable-linger carbonara
