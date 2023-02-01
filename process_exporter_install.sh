#!/usr/bin/env bash

set -e

echo "Configuring process_exporter to run ..."
sudo mkdir /config
echo "enabled: true" > /config/process.txt
echo "process_names:" >> /config/process.txt
echo "- name: \"{{.Comm}}\"" >> /config/process.txt
echo "  cmdline:" >> /config/process.txt
echo "    - '.+'" >> /config/process.txt

echo "Configuring process_exporter to run ..."
docker run -d --rm -p 9256:9256 --privileged -v /proc:/host/proc -v /config:/config ncabatoff/process-exporter --procfs /host/proc -config.path /config/process.yml
