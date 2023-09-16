#!/usr/bin/env bash
#================================================================
# HEADER
#================================================================
#% SYNOPSIS
#+    script usage: install_core_monitor.sh [<flags>]
#%
#% DESCRIPTION
#%    This is a script template to install and configure a centralized monitoring
#%    service leveraging open-source prometheus (OTEL) stack for publishing
#%    energy consumption and usage data for calculating carbon emission
#%    Please refer: https://trycarbonara.github.io/docs/dist/html/linux-machine.html
#%    Support: Linux (Ubuntu >= 22.04)
#%
#% OPTIONS
#%    -h : Show usage
#%    -u : Carbonara Username | Required
#%    -p : Carbonara Password | Required
#%    -r : Target Carbonara Remote Endpoint | Required
#%    -t : Target Carbonara Remote Port | Required
#%
#% EXAMPLES
#%    ./install_core_monitor.sh -g -u arg1 -p arg2 -r arg3 -o arg4
#%
#=========================================================================
#- IMPLEMENTATION
#-    version         install_core_monitor.sh (www.trycarbonara.com) 0.0.1
#-    author          Saurabh Sarkar
#-    copyright       Copyright (c) http://www.trycarbonara.com
#-    license         GNU General Public License
#-
#=========================================================================
#  HISTORY
#     09/16/2023 : saurabh-carbonara : Script creation
# 
#================================================================
#  DEBUG OPTION
#    set -n  # Uncomment to check your syntax, without execution.
#    set -x  # Uncomment to debug this shell script
#
#================================================================
# END_OF_HEADER
#================================================================

set +e

while getopts 'hn:i:u:p:r:t:d:s:e:glyc' OPTION; do
  case "$OPTION" in
    h)
      echo "script usage: $(basename $0) [<flags>]"
      echo "Flags:"
      echo "  -h : Show usage"
      echo "  -u : Carbonara Username | Required"
      echo "  -p : Carbonara Password | Required"
      echo "  -r : Target Carbonara Remote Endpoint | Required"
      echo "  -t : Target Carbonara Remote Port | Required"
      exit 0
      ;;
    u)
      uvalue="$OPTARG"
      ;;
    p)
      pvalue="$OPTARG"
      ;;
    r)
      rvalue="$OPTARG"
      ;;
    t)
      tvalue="$OPTARG"
      ;;
    ?)
      echo "script usage: $(basename $0) [<flags>]" >&2
      echo "Flags:" >&2
      echo "  -h : Show usage" >&2
      echo "  -u : Carbonara Username | Required" >&2
      echo "  -p : Carbonara Password | Required" >&2
      echo "  -r : Target Carbonara Remote Endpoint | Required" >&2
      echo "  -t : Target Carbonara Remote Port | Required" >&2
      exit 1
      ;;
  esac
done
shift "$(($OPTIND -1))"

if [ -z "$uvalue" ] || [ -z "$pvalue" ] ; then
    echo "Username/Password (account), to connect to Carbonara Service, is required. Use '-h' flag to learn more." >&2
    exit 1
fi

if [ -z "$rvalue" ] || [ -z "$tvalue" ] ; then
    echo "Carbonara service endpoint and port is required. Use '-h' flag to learn more." >&2
    exit 1
fi

echo -e "\n"
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo "@     Setting Carbonara Working Directory as '/carbonara'     @"
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
sudo mkdir -p /carbonara
sudo chmod 777 -R /carbonara/
cd /carbonara

echo -e "\n"
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo '@ Install/configure Prometheus Service @'
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"

sudo apt-get update
# sudo apt install -y net-tools
sudo apt-get install -y curl tar wget sed

# Download the source using wget, untar it, and rename the extracted folder to Prometheus-package.

wget https://github.com/prometheus/prometheus/releases/download/v2.32.1/prometheus-2.32.1.linux-amd64.tar.gz
tar -xvf prometheus-*.linux-amd64.tar.gz
mv prometheus-*.linux-amd64 prometheus-package

# Create a Prometheus user, and required directories, and make Prometheus the user as the owner of those directories.

sudo useradd --no-create-home --shell /bin/false prometheus
sudo mkdir /etc/prometheus
sudo mkdir /var/lib/prometheus
sudo chown prometheus:prometheus /etc/prometheus
sudo chown prometheus:prometheus /var/lib/prometheus

# Copy Prometheus and protocol binary from the Prometheus-package folder to /usr/local/bin and change the ownership to Prometheus user.

sudo cp prometheus-package/prometheus /usr/local/bin/
sudo cp prometheus-package/promtool /usr/local/bin/
sudo chown prometheus:prometheus /usr/local/bin/prometheus
sudo chown prometheus:prometheus /usr/local/bin/promtool

# Move the consoles and console_libraries directories from Prometheus-package to /etc/prometheus folder and change the ownership to Prometheus user.

sudo cp -r prometheus-package/consoles /etc/prometheus
sudo cp -r prometheus-package/console_libraries /etc/prometheus
sudo chown -R prometheus:prometheus /etc/prometheus/consoles
sudo chown -R prometheus:prometheus /etc/prometheus/console_libraries

if [ -f "/etc/prometheus/prometheus.yml" ]; then
    sudo cp /etc/prometheus/prometheus.yml /etc/prometheus/prometheus.yml.backup
    echo "Backing up existing prometheus.yml to '/etc/prometheus/prometheus.yml.backup'"
fi

if [ -f "/etc/systemd/system/prometheus.service" ]; then
    sudo cp /etc/systemd/system/prometheus.service /etc/systemd/system/prometheus.service.backup
    echo "Backing up existing prometheus.service to '/etc/systemd/system/prometheus.service.backup'"
fi

if [ -f "/etc/sysconfig/prometheus" ]; then
    sudo cp /etc/sysconfig/prometheus /etc/sysconfig/prometheus.backup
    echo "Backing up existing prometheus sysconfig to '/etc/sysconfig/prometheus.backup'"
    rm -rf /etc/sysconfig/prometheus
fi

sudo curl -fsSL https://raw.githubusercontent.com/TryCarbonara/NodeInstallation/main/client/core-prom-server/prometheus.service -o /etc/systemd/system/prometheus.service \
    && sudo curl -fsSL https://raw.githubusercontent.com/TryCarbonara/NodeInstallation/main/client/core-prom-server/prometheus.yml -o /etc/prometheus/prometheus.yml

sudo chown prometheus:prometheus /etc/prometheus/prometheus.yml

sed -i "s/\${PROM_INSTANCE}/$(hostname -I | cut -f1 -d' ')/g" /etc/prometheus/prometheus.yml
sed -i "s/\${REMOTE_ENDPOINT}/$rvalue" /etc/prometheus/prometheus.yml
sed -i "s/\${REMOTE_PORT}/$tvalue" /etc/prometheus/prometheus.yml
sed -i "s/\${AUTH_UNAME}/$uvalue" /etc/prometheus/prometheus.yml
sed -i "s/\${AUTH_PWD}/$pvalue" /etc/prometheus/prometheus.yml

sudo systemctl daemon-reload \
    && sudo systemctl start prometheus \
    && sudo systemctl enable prometheus

echo -e "Cleaning not-in-use packages"
sudo apt -y autoremove

echo -e "\n"
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo "@            You are all set to start publishing metrics to Carbonara             @"
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo -e "Please make sure to whitelist (egress) endpoint=$rvalue:$tvalue, if applicable."
