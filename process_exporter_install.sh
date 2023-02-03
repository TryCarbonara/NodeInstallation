#!/usr/bin/env bash

set -e

echo "Configuring process_exporter resources ..."
sudo mkdir -p ./config
echo "enabled: true" > ./config/process.yml
echo "process_names:" >> ./config/process.yml
echo "- name: \"{{.Comm}}\"" >> ./config/process.yml
echo "  cmdline:" >> ./config/process.yml
echo "    - '.+'" >> ./config/process.yml

echo "Configuring process_exporter to run ..."
docker run -d --rm -p 9256:9256 --privileged -v /proc:/host/proc -v `pwd`/config:/config ncabatoff/process-exporter --procfs /host/proc -config.path /config/process.yml
