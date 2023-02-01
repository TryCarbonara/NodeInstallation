#!/usr/bin/env bash

set -e

echo "Configuring node_exporter to run ..."
docker run -d \
--net="host" \
--pid="host" \
-v "/:/host:ro,rslave" \
quay.io/prometheus/node-exporter:latest \
--path.rootfs=/host --collector.processes \
--collector.systemd --collector.tcpstat \
--collector.diskstats.ignored-devices="^(ram|loop|fd)\\\\d+$"
