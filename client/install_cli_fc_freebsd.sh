#!/usr/bin/env sh
#================================================================
# HEADER
#================================================================
#% SYNOPSIS
#+    script usage: install_cli_fc_freebsd.sh [<flags>]
#%
#% DESCRIPTION
#%    This is a script template to install and configure required toolings for
#%    publishing energy consumption and usage data for calculating carbon emission
#%    Please refer: https://trycarbonara.github.io/docs/dist/html/linux-machine.html
#%    Support: Linux (FreeBSD/FreeNAS), Kernel >= 5
#%
#% OPTIONS
#%    -h : Show usage
#%    -n : node-exporter port | Default: 9100
#%    -i : ipmi-exporter port | Default: 9290
#%    -u : Carbonara Username | Required
#%    -p : Carbonara Password | Required
#%    -r : Target Carbonara Remote Endpoint | Required
#%    -t : Target Carbonara Remote Port | Required
#%
#% EXAMPLES
#%    ./install_cli_fc_freebsd.sh -g -u arg1 -p arg2 -r arg3 -o arg4
#%
#===========================================================================
#- IMPLEMENTATION
#-    version         install_cli_fc_freebsd.sh (www.trycarbonara.com) 0.0.1
#-    author          Saurabh Sarkar
#-    copyright       Copyright (c) http://www.trycarbonara.com
#-    license         GNU General Public License
#-
#===========================================================================
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

# sudo chmod +x install_cli.sh

while getopts 'hn:i:u:p:r:t:' OPTION; do
  case "$OPTION" in
    h)
      echo "script usage: $(basename $0) [<flags>]"
      echo "Flags:"
      echo "  -h : Show usage"
      echo "  -n : node-exporter port | Default: 9100"
      echo "  -i : ipmi-exporter port | Default: 9290"
      echo "  -u : Carbonara Username | Required"
      echo "  -p : Carbonara Password | Required"
      echo "  -r : Target Carbonara Remote Endpoint | Required"
      echo "  -t : Target Carbonara Remote Port | Required"
      exit 0
      ;;
    n)
      nvalue="$OPTARG"
      ;;
    i)
      ivalue="$OPTARG"
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
      echo "  -n : node-exporter port | Default: 9100" >&2
      echo "  -i : ipmi-exporter port | Default: 9290" >&2
      echo "  -u : Carbonara Username | Required" >&2
      echo "  -p : Carbonara Password | Required" >&2
      echo "  -r : Target Carbonara Remote Endpoint | Required" >&2
      echo "  -t : Target Carbonara Remote Port | Required" >&2
      exit 1
      ;;
  esac
done
shift "$(($OPTIND -1))"

if [ -z "$nvalue" ] ; then
  echo -e "node-exporter port is picking default value: 9100."
  nvalue=9100
fi

if [ -z "$ivalue" ] ; then
  echo -e "ipmi-exporter port is picking default value: 9290."
  ivalue=9290
fi

if [ -z "$uvalue" ] || [ -z "$pvalue" ] ; then
  echo "Username/Password (account), to connect to Carbonara Service, is required. Use '-h' flag to learn more." >&2
  exit 1
fi

if [ -z "$rvalue" ] || [ -z "$tvalue" ] ; then
  echo "Carbonara service endpoint and port is required. Use '-h' flag to learn more." >&2
  exit 1
fi

# pre-req
echo -e "\n"
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo "@     Setting Carbonara Working Directory as '/carbonara'     @"
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
mkdir -p /carbonara
chmod 777 /carbonara
cd /carbonara
pkg install -y curl

# node-exporter
echo -e "\n"
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo '@   Install node exporter tool, for host resource usage data   @'
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
# enable module which provides access to thermal sensors and power management features, including RAPL data
kldload coretemp || true
echo "Installing Node Exporter ..."
# sed -i .backup 's/node_exporter_args:=""/node_exporter_args:="--collector.uname --collector.meminfo --collector.cpu --web.disable-exporter-metrics"/g' /usr/local/etc/rc.d/node_exporter
fetch https://raw.githubusercontent.com/TryCarbonara/NodeInstallation/main/client/node-exporter/node_exporter.freebsd -o /usr/local/bin/node_exporter \
  && chmod +x /usr/local/bin/node_exporter \
  && chown root:wheel /usr/local/bin/node_exporter
fetch https://raw.githubusercontent.com/TryCarbonara/NodeInstallation/main/client/node-exporter/node_exporter.rc.d -o /usr/local/etc/rc.d/node_exporter \
  && chmod +x /usr/local/etc/rc.d/node_exporter \
  && sysrc node_exporter_enable=YES \
  && sysrc node_exporter_args="--collector.meminfo --collector.uname --collector.cpu --web.disable-exporter-metrics" \
  && sysrc node_exporter_listen_address=":$nvalue" \
  && sysrc node_exporter_user="root" \
  && sysrc node_exporter_group="root" \
  && service node_exporter restart

# FreeIPMI
echo -e "\n"
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo '@ Install IPMI exporter tool, for host power consumption data  @'
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
# enable ipmi if underlying h/w & kernel supports it
kldload ipmi || true
kldload ipmi_drv || true
echo 'ipmi_load="YES"' >> /boot/loader.conf
pkg install -y sysutils/freeipmi ipmitool
sysrc freeipmi_enable=YES
sysrc ipmitool_enable=YES
fetch -o - https://github.com/prometheus-community/ipmi_exporter/releases/download/v1.6.1/ipmi_exporter-1.6.1.freebsd-amd64.tar.gz \
  | tar -xzvf - -C /usr/local/bin --strip-components=1 ipmi_exporter-1.6.1.freebsd-amd64/ipmi_exporter \
  && chown root:wheel /usr/local/bin/ipmi_exporter

fetch https://raw.githubusercontent.com/TryCarbonara/NodeInstallation/main/client/ipmi-exporter/ipmi_exporter.rc.d -o /usr/local/etc/rc.d/ipmi_exporter \
  && fetch https://raw.githubusercontent.com/TryCarbonara/NodeInstallation/main/ipmi_local.yml -o /carbonara/ipmi_local.yml \
  && sysrc ipmi_exporter_enable=YES \
  && sysrc ipmi_exporter_config_file="/carbonara/ipmi_local.yml" \
  && sysrc ipmi_exporter_listen_address=":$ivalue" \
  && chmod +x /usr/local/etc/rc.d/ipmi_exporter \
  && service ipmi_exporter restart

# grafana-agent
echo -e "\n"
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo "@     Install Grafana Agent, for enabling metrics push      @"
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
fetch https://github.com/grafana/agent/releases/download/v0.36.2/grafana-agent-freebsd-amd64.zip -o grafana-agent-freebsd-amd64.zip \
  && unzip grafana-agent-freebsd-amd64.zip \
  && chmod +x grafana-agent-freebsd-amd64 \
  && mv grafana-agent-freebsd-amd64 /usr/local/bin/grafana_agent \
  && chown root:wheel /usr/local/bin/grafana_agent

fetch https://raw.githubusercontent.com/TryCarbonara/NodeInstallation/main/client/grafana-agent/grafana_agent.rc.d -o /usr/local/etc/rc.d/grafana_agent \
  && fetch https://raw.githubusercontent.com/TryCarbonara/NodeInstallation/main/client/grafana-agent/agent-client-fc.yaml -o /etc/grafana-agent.yaml
ip_addr=$(ifconfig | grep -Eo 'inet (addr:)?[0-9\.]+' | awk '{print $2}' | grep -v '127.0.0.1' | sed -n '2p')
sed -i -e "s/\${INSTANCE}/$ip_addr/g" /etc/grafana-agent.yaml
sed -i -e "s/\${PROVIDER}/$uvalue/g" /etc/grafana-agent.yaml
sed -i -e "s/\${HOSTNAME}/$(hostname)/g" /etc/grafana-agent.yaml
sed -i -e "s/\${REMOTE_ENDPOINT}/$rvalue/g" /etc/grafana-agent.yaml
sed -i -e "s/\${REMOTE_PORT}/$tvalue/g" /etc/grafana-agent.yaml
sed -i -e "s/\${AUTH_UNAME}/$uvalue/g" /etc/grafana-agent.yaml
sed -i -e "s/\${AUTH_PWD}/$pvalue/g" /etc/grafana-agent.yaml
sed -i -e "s/\${NODE_PORT}/$nvalue/g" /etc/grafana-agent.yaml
sed -i -e "s/\${IPMI_PORT}/$ivalue/g" /etc/grafana-agent.yaml

chmod +x /usr/local/etc/rc.d/grafana_agent \
  && sysrc grafana_agent_enable=YES \
  && sysrc grafana_agent_config_file="/etc/grafana-agent.yaml" \
  && service grafana_agent restart

echo -e "\n"
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo "@            You are all set to start publishing metrics to Carbonara             @"
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo -e "Please make sure to whitelist (egress) endpoint=$rvalue:$tvalue, if applicable."
echo "Happy Carbonara !!"
