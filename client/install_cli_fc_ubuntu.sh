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
#%    -c : Check Status | Default: false
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
cvalue=false

while getopts 'hn:i:u:p:r:t:d:glc' OPTION; do
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
      echo "  -c : Check Status | Default: false"
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
    c)
      cvalue=true
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
      echo "  -c : Check Status | Default: false" >&2
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

if [ "$gvalue" == true ] ; then
  if [ -z "$dvalue" ] ; then
    echo -e "dcgm-exporter port is picking default value: 9400."
    dvalue=9400
  fi
fi

if [ "$cvalue" == true ] ; then
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

  echo -n "Checking if port is open to use (node-exporter) ..."
  n_inuse=$((echo >/dev/tcp/localhost/$nvalue) &>/dev/null && echo "open" || echo "close")
  if [ "$n_inuse" == "open" ] ; then
    echo " Port already in use" >&2
    exit 1
  else
  echo " Success"
  fi

  echo -n "Checking if port is open to use (ipmi-exporter) ..."
  i_inuse=$((echo >/dev/tcp/localhost/$ivalue) &>/dev/null && echo "open" || echo "close")
  if [ "$i_inuse" == "open" ] ; then
    echo " Port already in use" >&2
    exit 1
  else
  echo " Success"
  fi

  echo -n "Checking if port is open to use (dcgm-exporter) ..."
  d_inuse=$((echo >/dev/tcp/localhost/$dvalue) &>/dev/null && echo "open" || echo "close")
  if [ "$d_inuse" == "open" ] ; then
    echo " Port already in use" >&2
    exit 1
  else
  echo " Success"
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
  sudo apt-get install -y curl tar wget
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
    echo "Installing FreeIPMI tool suite ..."
    sudo apt-get update && sudo apt-get install freeipmi-tools -y --no-install-recommends && sudo rm -rf /var/lib/apt/lists/*

    echo "Installing IPMI Exporter ..."
    # IPMI Exporter
    sudo curl -fsSL https://github.com/prometheus-community/ipmi_exporter/releases/download/v1.6.1/ipmi_exporter-1.6.1.linux-amd64.tar.gz \
    | sudo tar -zxvf - -C /usr/local/bin --strip-components=1 ipmi_exporter-1.6.1.linux-amd64/ipmi_exporter \
    && sudo chown root:root /usr/local/bin/ipmi_exporter

    if [ -f "/etc/systemd/system/ipmi_exporter.service" ]; then
      sudo cp /etc/systemd/system/ipmi_exporter.service /etc/systemd/system/ipmi_exporter.service.backup
      echo "Backing up existing ipmi_exporter.service to '/etc/systemd/system/ipmi_exporter.service.backup'"
    fi
    if [ -f "/etc/sysconfig/ipmi_exporter" ]; then
      sudo cp /etc/sysconfig/ipmi_exporter /etc/sysconfig/ipmi_exporter.backup
      echo "Backing up existing ipmi_exporter sysconfig to '/etc/sysconfig/ipmi_exporter.backup'"
    fi

    sudo curl -fsSL https://raw.githubusercontent.com/TryCarbonara/NodeInstallation/main/client/ipmi-exporter/ipmi_exporter.service -o /etc/systemd/system/ipmi_exporter.service \
      && sudo mkdir -p /etc/sysconfig \
      && sudo echo 'OPTIONS="--config.file=/carbonara/ipmi_local.yml --web.listen-address=:'$ivalue'"' | sudo tee /etc/sysconfig/ipmi_exporter > /dev/null \
      && sudo curl -fsSL https://raw.githubusercontent.com/TryCarbonara/NodeInstallation/main/ipmi_local.yml -o /carbonara/ipmi_local.yml

    sudo systemctl daemon-reload \
      && sudo systemctl restart ipmi_exporter \
      && sudo systemctl enable ipmi_exporter
  else
    echo "IPMI is not available."
    echo "Enabling RAPL module instead, for supported Architecture"
    modprobe intel_rapl_common || true
  fi

  if [ "$gvalue" == true ] ; then
    echo -e "\n"
    echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    echo '@ **Step 2:** Install DCGM exporter tool, for host **GPU (Nvidia)** power consumption data  @'
    echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    echo "Current VGA devices:"
    lspci | grep -E 'VGA|Display ' | cut -d" " -f 1 | xargs -i lspci -v -s {}

    if [ -x "$(command -v nvidia-smi)" ] ; then
      echo "Installing DCGM GPU Manager ..."
      # set up the CUDA repository GPG key
      # assuming x86_64 arch
      sudo curl -fsSL https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.0-1_all.deb -o cuda-keyring_1.0-1_all.deb \
        && sudo dpkg -i cuda-keyring_1.0-1_all.deb \
        && sudo add-apt-repository "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/ /"

      # install GPU Manager
      sudo apt update && sudo apt install -y datacenter-gpu-manager \
        && sudo systemctl enable nvidia-dcgm \
        && sudo systemctl restart nvidia-dcgm
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
        && sudo echo 'OPTIONS="--address=:'$dvalue'"' | sudo tee /etc/sysconfig/dcgm_exporter > /dev/null \
        && sudo mkdir -p /etc/dcgm-exporter \
        && sudo curl -fsSL https://raw.githubusercontent.com/TryCarbonara/NodeInstallation/main/client/dcgm-exporter/default-counters.csv -o /etc/dcgm-exporter/default-counters.csv \
        && sudo curl -fsSL https://raw.githubusercontent.com/TryCarbonara/NodeInstallation/main/client/dcgm-exporter/dcp-metrics-included.csv -o /etc/dcgm-exporter/dcp-metrics-included.csv

      sudo systemctl daemon-reload \
        && sudo systemctl restart dcgm_exporter \
        && sudo systemctl enable dcgm_exporter
    fi
  else
    echo "Skipping GPU ..."
  fi

  echo -e "\n"
  echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
  echo '@   **Step 3:** Install node exporter tool, for host resource usage data   @'
  echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
  echo "Installing Node Exporter ..."
  sudo curl -fsSL https://github.com/prometheus/node_exporter/releases/download/v1.3.1/node_exporter-1.3.1.linux-amd64.tar.gz \
    | sudo tar -zxvf - -C /usr/local/bin --strip-components=1 node_exporter-1.3.1.linux-amd64/node_exporter \
    && sudo chown root:root /usr/local/bin/node_exporter

  if [ -f "/etc/systemd/system/node_exporter.service" ]; then
    sudo cp /etc/systemd/system/node_exporter.service /etc/systemd/system/node_exporter.service.backup
    echo "Backing up existing node_exporter.service to '/etc/systemd/system/node_exporter.service.backup'"
  fi
  if [ -f "/etc/sysconfig/node_exporter" ]; then
    sudo cp /etc/sysconfig/node_exporter /etc/sysconfig/node_exporter.backup
    echo "Backing up existing node_exporter sysconfig to '/etc/sysconfig/node_exporter.backup'"
  fi

  sudo curl -fsSL https://raw.githubusercontent.com/TryCarbonara/NodeInstallation/main/client/node-exporter/node_exporter.service -o /etc/systemd/system/node_exporter.service \
    && sudo mkdir -p /etc/sysconfig \
    && sudo echo 'OPTIONS="--collector.uname --collector.processes --collector.systemd --collector.tcpstat --collector.cpu.info --collector.rapl --collector.systemd.enable-task-metrics --web.disable-exporter-metrics --collector.diskstats.ignored-devices=\"^(ram|loop|fd|nfs)\\d+$\" --collector.zfs --web.listen-address=:'$nvalue'"' | sudo tee /etc/sysconfig/node_exporter > /dev/null

  sudo systemctl daemon-reload \
    && sudo systemctl restart node_exporter \
    && sudo systemctl enable node_exporter

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

    sudo echo "INSTANCE=$(hostname -I | cut -f1 -d' ')" | sudo tee -a /etc/default/grafana-agent > /dev/null
    sudo echo "PROVIDER=$uvalue" | sudo tee -a /etc/default/grafana-agent > /dev/null
    sudo echo "HOSTNAME=$(hostname)" | sudo tee -a /etc/default/grafana-agent > /dev/null
    sudo echo "REMOTE_ENDPOINT=$rvalue" | sudo tee -a /etc/default/grafana-agent > /dev/null
    sudo echo "REMOTE_PORT=$tvalue" | sudo tee -a /etc/default/grafana-agent > /dev/null
    sudo echo "AUTH_UNAME=$uvalue" | sudo tee -a /etc/default/grafana-agent > /dev/null
    sudo echo "AUTH_PWD=$pvalue" | sudo tee -a /etc/default/grafana-agent > /dev/null
    sudo echo "NODE_PORT=$nvalue" | sudo tee -a /etc/default/grafana-agent > /dev/null
    sudo echo "IPMI_PORT=$ivalue" | sudo tee -a /etc/default/grafana-agent > /dev/null
    sudo echo "DCGM_PORT=$dvalue" | sudo tee -a /etc/default/grafana-agent > /dev/null

    sudo systemctl daemon-reload \
      && sudo systemctl restart grafana-agent \
      && sudo systemctl enable grafana-agent
  else
    echo "Skipping ..."
  fi

  echo -e "Cleaning not-in-use packages"
  sudo apt -y autoremove

  echo -e "\n"
  echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
  echo "@            You are all set to start publishing metrics to Carbonara             @"
  echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
  echo -e "Please make sure to whitelist (egress) endpoint=$rvalue:$tvalue, if applicable."
  figlet -t -k Happy Carbonara !!
fi
