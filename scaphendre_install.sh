#!/usr/bin/env bash

set -e

echo "Adding Inter_RAPL_Common Module to Kernel (>= 5.X.X)"
# If kernel < 5, apply `modprobe intel_rapl` instead
modprobe intel_rapl_common

echo "Configuring hubblo/scaphandre to run ..."
docker run -d -v /sys/class/powercap:/sys/class/powercap -v /proc:/proc -p 8080:8080 -ti hubblo/scaphandre prometheus
