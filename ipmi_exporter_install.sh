#!/usr/bin/env bash

set -e

echo 'Customers are encouraged to leverage `systemd` for managing the tool (exporter) for better reliability'
# FreeIPMI
apt-get update && apt-get install freeipmi-tools -y --no-install-recommends && rm -rf /var/lib/apt/lists/*

# IPMI Exporter
wget https://github.com/prometheus-community/ipmi_exporter/releases/download/v1.6.1/ipmi_exporter-1.6.1.linux-amd64.tar.gz
tar xfvz ipmi_exporter-1.6.1.linux-amd64.tar.gz
rm ipmi_exporter-1.6.1.linux-amd64.tar.gz
./ipmi_exporter-1.6.1.linux-amd64/ipmi_exporter --config.file=ipmi_local.yml &
