#!/usr/bin/env bash
#================================================================
# HEADER
#================================================================
#% SYNOPSIS
#+    script usage: install_cli_fc_ubuntu.sh [<flags>]
#%
#% DESCRIPTION
#%    This is a script template to install and configure required toolings for
#%    publishing energy consumption and usage data for calculating carbon emission
#%    Please refer: https://trycarbonara.github.io/docs/dist/html/linux-machine.html
#%    Support: Linux (Ubuntu >= 22.04), Kernel >= 5
#%
#% OPTIONS
#%    -h : Show usage
#%    -g : gpu-support | Default: false
#%    -n : node-exporter port | Default: 9100
#%    -i : ipmi-exporter port | Default: 9290
#%    -d : dcgm-exporter port | Default: 9400
#%    -u : Carbonara Username | Required
#%    -p : Carbonara Password | Required
#%    -r : Target Carbonara Remote Endpoint | Required
#%    -t : Target Carbonara Remote Port | Required
#%    -l : Local | Default: false
#%    -k : Check Status | Default: false
#%
#% EXAMPLES
#%    ./install_cli_fc_ubuntu.sh -g -u arg1 -p arg2 -r arg3 -o arg4
#%
#==========================================================================
#- IMPLEMENTATION
#-    version         install_cli_fc_ubuntu.sh (www.trycarbonara.com) 0.0.1
#-    author          Saurabh Sarkar
#-    copyright       Copyright (c) http://www.trycarbonara.com
#-    license         GNU General Public License
#-
#==========================================================================
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
gvalue=false
lvalue=false
kvalue=false

while getopts 'hn:i:u:p:r:t:d:glk' OPTION; do
  case "$OPTION" in
    h)
      echo "script usage: $(basename $0) [<flags>]"
      echo "Flags:"
      echo "  -h : Show usage"
      echo "  -g : gpu-support | Default: false"
      echo "  -n : node-exporter port | Default: 9100"
      echo "  -i : ipmi-exporter port | Default: 9290"
      echo "  -d : dcgm-exporter port | Default: 9400"
      echo "  -u : Carbonara Username | Required"
      echo "  -p : Carbonara Password | Required"
      echo "  -r : Target Carbonara Remote Endpoint | Required"
      echo "  -t : Target Carbonara Remote Port | Required"
      echo "  -l : Local | Default: false"
      echo "  -k : Check Status | Default: false"
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
    g)
      gvalue=true
      ;;
    l)
      lvalue=true
      ;;
    d)
      dvalue="$OPTARG"
      ;;
    k)
      kvalue=true
      ;;
    ?)
      echo "script usage: $(basename $0) [<flags>]" >&2
      echo "Flags:" >&2
      echo "  -h : Show usage" >&2
      echo "  -g : gpu-support | Default: False" >&2
      echo "  -n : node-exporter port | Default: 9100" >&2
      echo "  -i : ipmi-exporter port | Default: 9290" >&2
      echo "  -d : dcgm-exporter port | Default: 9400" >&2
      echo "  -u : Carbonara Username | Required" >&2
      echo "  -p : Carbonara Password | Required" >&2
      echo "  -r : Target Carbonara Remote Endpoint | Required" >&2
      echo "  -t : Target Carbonara Remote Port | Required" >&2
      echo "  -l : Local | Default: false" >&2
      echo "  -k : Check Status | Default: false" >&2
      exit 1
      ;;
  esac
done
shift "$(($OPTIND -1))"

if [ "$kvalue" == true ] ; then
  echo -e "\n"
  echo "Checking Status... "
  if ls /dev/ipmi* 1> /dev/null 2>&1; then
    echo -n "Checking port (ipmi-exporter) ..."
    i_inuse=$((echo >/dev/tcp/localhost/$ivalue) &>/dev/null && echo "open" || echo "close")
    if [ "$i_inuse" == "open" ] ; then
      echo " Port in use" >&2
    else
      echo " Port not in use" >&2
    fi
    sd=$(sudo systemctl status ipmi_exporter.service)
    if [ $? == 0 ]; then
      echo "IPMI Exporter ... Succeeded"
    else
      echo "IPMI Exporter ... Failed"
    fi
  else
    echo "IPMI Exporter ... Not Supported"
  fi

  if [ "$gvalue" == true ] ; then
    echo -n "Checking port (dcgm-exporter) ..."
    d_inuse=$((echo >/dev/tcp/localhost/$dvalue) &>/dev/null && echo "open" || echo "close")
    if [ "$d_inuse" == "open" ] ; then
      echo " Port in use" >&2
    else
      echo " Port not in use" >&2
    fi
    sd=$(sudo systemctl status dcgm_exporter.service)
    if [ $? == 0 ]; then
      echo "DCGM Exporter ... Succeeded"
    else
      echo "DCGM Exporter ... Failed"
    fi
  fi

  echo -n "Checking port (node-exporter) ..."
  n_inuse=$((echo >/dev/tcp/localhost/$nvalue) &>/dev/null && echo "open" || echo "close")
  if [ "$n_inuse" == "open" ] ; then
    echo " Port in use" >&2
  else
    echo " Port not is use" >&2
  fi
  sd=$(sudo systemctl status node_exporter.service)
  if [ $? == 0 ]; then
    echo "Node Exporter ... Succeeded"
  else
    echo "Node Exporter ... Failed"
  fi

  sd=$(sudo systemctl status grafana-agent.service)
  if [ $? == 0 ]; then
    echo "Grafana Agent ... Succeeded"
  else
    echo "Grafana Agent ... Failed"
  fi
else
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
  echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
  echo "@  **Step 0:** Installing pre-requisites for supporting Carbonara Setup  @"
  echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
  sudo apt-get update
  sudo apt install -y net-tools
  sudo apt-get install -y curl tar wget sed
  sudo apt install -y figlet
  # sudo useradd --system --shell /bin/false carbonara_exporter || \
  #   echo "User already exists."

  echo -e "\n"
  echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
  echo '@ **Step 1:** Install IPMI exporter tool, for host power consumption data  @'
  echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
  # FreeIPMI
  # enable ipmi if underlying h/w & kernel supports it
  sudo modprobe ipmi_devintf || true
  sudo modprobe ipmi_si || true

  # check if ipmi is supported
  if ls /dev/ipmi* 1> /dev/null 2>&1; then
    echo "IPMI already setup"
  else
    echo "IPMI is not available."
    echo "Enabling RAPL module instead, for supported Architecture"
    modprobe intel_rapl_common || true
    sudo systemctl daemon-reload \
      && sudo systemctl restart node_exporter \
      && sudo systemctl enable node_exporter
  fi

  echo -e "\n"
  echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
  echo "@     **Step 4:** Install Grafana Agent, for enabling metrics push      @"
  echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
  if [ $lvalue == false ] ; then
    sudo mkdir -p /etc/apt/keyrings/
    wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | sudo tee /etc/apt/keyrings/grafana.gpg > /dev/null
    echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | sudo tee /etc/apt/sources.list.d/grafana.list > /dev/null

    sudo apt-get update && sudo apt-get install -y grafana-agent

    if [ -f "/etc/grafana-agent.yaml" ]; then
      sudo cp /etc/grafana-agent.yaml /etc/grafana-agent.yaml.backup
      echo "Backing up existing grafana-agent config file to '/etc/grafana-agent.yaml.backup'"
    fi
    if [ -f "/etc/default/grafana-agent" ]; then
      sudo cp /etc/default/grafana-agent /etc/default/grafana-agent.backup
      echo "Backing up existing grafana-agent sysconfig to '/etc/default/grafana-agent.backup'"
    fi

    sudo curl -fsSL https://raw.githubusercontent.com/TryCarbonara/NodeInstallation/main/client/grafana-agent/agent-client-fc.yaml -o /etc/grafana-agent.yaml && \
    sudo curl -fsSL https://raw.githubusercontent.com/TryCarbonara/NodeInstallation/main/client/grafana-agent/sysconfig.grafana_agent -o /etc/default/grafana-agent

    sudo sed -i "s/\${INSTANCE}/$(hostname -I | cut -f1 -d' ')/g" /etc/grafana-agent.yaml
    sudo sed -i "s/\${PROVIDER}/$uvalue/g" /etc/grafana-agent.yaml
    sudo sed -i "s/\${HOSTNAME}/$(hostname)/g" /etc/grafana-agent.yaml
    sudo sed -i "s/\${REMOTE_ENDPOINT}/$rvalue/g" /etc/grafana-agent.yaml
    sudo sed -i "s/\${REMOTE_PORT}/$tvalue/g" /etc/grafana-agent.yaml
    sudo sed -i "s/\${AUTH_UNAME}/$uvalue/g" /etc/grafana-agent.yaml
    sudo sed -i "s/\${AUTH_PWD}/$pvalue/g" /etc/grafana-agent.yaml
    sudo sed -i "s/\${NODE_PORT}/$nvalue/g" /etc/grafana-agent.yaml
    sudo sed -i "s/\${IPMI_PORT}/$ivalue/g" /etc/grafana-agent.yaml
    sudo sed -i "s/\${DCGM_PORT}/$dvalue/g" /etc/grafana-agent.yaml

    sudo systemctl daemon-reload \
      && sudo systemctl restart grafana-agent \
      && sudo systemctl enable grafana-agent
  else
    echo "Skipping ..."
  fi

  echo -e "\n"
  echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
  echo "@            You are all set to start publishing metrics to Carbonara             @"
  echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
  echo -e "Please make sure to whitelist (egress) endpoint=$rvalue:$tvalue, if applicable."
  figlet -t -k Happy Carbonara !!
fi
