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
#%    -n : node-exporter port | Default: 9100
#%    -i : ipmi-exporter port | Default: 9290
#%    -d : dcgm-exporter port | Default: 9400
#%    -s : smi-gpu-exporter port | Default: 9835
#%    -u : Carbonara Username | Required
#%    -p : Carbonara Password | Required
#%    -r : Target Carbonara Remote Endpoint | Required
#%    -v : Verbose | Default: false
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
#     11/30/2023 : saurabh-carbonara : Script creation
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

kvalue=false
vvalue=false

display_usage() { 
  echo "script usage: $(basename $0) [<flags>]" >&2
  echo "Flags:" >&2
  echo "  -h : Show usage" >&2
  echo "  -n : node-exporter port | Default: 9100" >&2
  echo "  -i : ipmi-exporter port | Default: 9290" >&2
  echo "  -d : dcgm-exporter port | Default: 9400" >&2
  echo "  -s : smi-gpu-exporter port | Default: 9835" >&2
  echo "  -u : Carbonara Username | Required" >&2
  echo "  -p : Carbonara Password | Required" >&2
  echo "  -r : Target Carbonara Remote Endpoint | Required" >&2
  echo "  -v : Verbose | Default: false" >&2
  echo "  -k : Check Status | Default: false" >&2
}

parse_params() {
  while getopts 'hn:i:u:p:r:t:d:ks:kv' OPTION; do
    case "$OPTION" in
      h)
        display_usage
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
      d)
        dvalue="$OPTARG"
        ;;
      s)
        svalue="$OPTARG"
        ;;
      k)
        kvalue=true
        ;;
      v)
        vvalue=true
        ;;
      ?)
        display_usage
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

  if [ -z "$dvalue" ] ; then
    echo -e "dcgm-exporter port is picking default value: 9400."
    dvalue=9400
  fi

  if [ -z "$svalue" ] ; then
    echo -e "smi-gpu-exporter port is picking default value: 9835."
    svalue=9835
  fi
}

check() {
  with_exit=$1
  echo -e "\n"
  echo "Checking Status... "
  if ls /dev/ipmi* 1> /dev/null 2>&1; then
    echo -n "Checking port (ipmi-exporter) ..."
    i_inuse=$((echo >/dev/tcp/localhost/$ivalue) &>/dev/null && echo "open" || echo "close")
    if [ "$i_inuse" == "open" ] ; then
      echo " Port in use" >&2
      if [ "$with_exit" == true ] ; then
        exit 1
      fi
    else
      echo " Port not in use" >&2
    fi
    sd=$(systemctl status ipmi_exporter.service)
    if [ $? == 0 ]; then
      echo "IPMI Exporter ... Succeeded"
    else
      echo "IPMI Exporter ... Failed"
    fi
  else
    echo "IPMI Exporter ... Not Supported"
  fi

  echo -n "Checking port (smi-gpu-exporter) ..."
  s_inuse=$((echo >/dev/tcp/localhost/$svalue) &>/dev/null && echo "open" || echo "close")
  if [ "$s_inuse" == "open" ] ; then
    echo " Port in use" >&2
    if [ "$with_exit" == true ] ; then
      exit 1
    fi
  else
    echo " Port not in use" >&2
  fi
  sd=$(systemctl status nvidia_gpu_exporter)
  if [ $? == 0 ]; then
    echo "SMI GPU Exporter ... Succeeded"
  else
    echo "SMI GPU Exporter ... Failed"
  fi

  echo -n "Checking port (node-exporter) ..."
  n_inuse=$((echo >/dev/tcp/localhost/$nvalue) &>/dev/null && echo "open" || echo "close")
  if [ "$n_inuse" == "open" ] ; then
    echo " Port in use" >&2
    if [ "$with_exit" == true ] ; then
      exit 1
    fi
  else
    echo " Port not is use" >&2
  fi
  sd=$(systemctl status node_exporter.service)
  if [ $? == 0 ]; then
    echo "Node Exporter ... Succeeded"
  else
    echo "Node Exporter ... Failed"
  fi

  sd=$(systemctl status grafana-agent.service)
  if [ $? == 0 ]; then
    echo "Grafana Agent ... Succeeded"
  else
    echo "Grafana Agent ... Failed"
  fi
}

setup_workdir() {
  CONFIG_DIR_USER=~/.config/systemd/user
  SYSCONFIG_DIR_USER=~/.config/sysconfig
  BIN_DIR_USER=~/bin
  LIB_DIR_USER=~/lib
  WORK_DIR=~/carbonara
  mkdir -p $CONFIG_DIR_USER
  mkdir -p $SYSCONFIG_DIR_USER
  mkdir -p $BIN_DIR_USER
  mkdir -p $WORK_DIR
  mkdir -p $LIB_DIR_USER
  cd $WORK_DIR
}

setup_ipmi() {
  # check if ipmi is supported
  if ls /dev/ipmi* 1> /dev/null 2>&1; then
    echo "Installing IPMI Exporter ..."
    # IPMI Exporter
    curl -fsSL https://github.com/prometheus-community/ipmi_exporter/releases/download/v1.6.1/ipmi_exporter-1.6.1.linux-amd64.tar.gz \
    | tar -zxvf - -C $BIN_DIR_USER --strip-components=1 ipmi_exporter-1.6.1.linux-amd64/ipmi_exporter \
    && chown carbonara:carbonara $BIN_DIR_USER/ipmi_exporter

    if [ -f "$CONFIG_DIR_USER/ipmi_exporter.service" ]; then
      cp $CONFIG_DIR_USER/ipmi_exporter.service $CONFIG_DIR_USER/.service.backup
      echo "Backing up existing ipmi_exporter.service to '$CONFIG_DIR_USER/.service.backup'"
    fi
    if [ -f "$SYSCONFIG_DIR_USER/ipmi_exporter" ]; then
      cp  $SYSCONFIG_DIR_USER/ipmi_exporter $SYSCONFIG_DIR_USER/ipmi_exporter.backup
      echo "Backing up existing ipmi_exporter sysconfig to '$SYSCONFIG_DIR_USER/ipmi_exporter.backup'"
    fi

    curl -fsSL https://raw.githubusercontent.com/TryCarbonara/NodeInstallation/main/client/ipmi-exporter/ipmi_exporter-vector.service -o $CONFIG_DIR_USER/ipmi_exporter.service \
      && echo 'OPTIONS="--config.file=$WORK_DIR/ipmi_local.yml --web.listen-address='localhost:$ivalue'"' | tee $SYSCONFIG_DIR_USER/ipmi_exporter > /dev/null \
      && curl -fsSL https://raw.githubusercontent.com/TryCarbonara/NodeInstallation/main/ipmi_local.yml -o $WORK_DIR/ipmi_local.yml
    
    systemctl --user daemon-reload \
      && systemctl --user restart ipmi_exporter \
      && systemctl --user enable ipmi_exporter
  else
    echo "Skipping ... IPMI is not supported."
  fi
}

setup_gpu() {
  echo "Current VGA devices:"
  lspci | grep -E 'VGA|Display ' | cut -d" " -f 1 | xargs -i lspci -v -s {}

  if [ -x "$(command -v nvidia-smi)" ] ; then
    sd=$(systemctl status dcgm_exporter.service)
    if [ $? == 0 ]; then
      echo "Skipping DCGM GPU Manager ..."
    else
      echo "Installing DCGM Exporter ..."
      # DCGM Exporter
      curl -fsSL https://client-installables-shared.s3.us-west-1.amazonaws.com/dcgm-exporter-x86_64-3_1_7 -o $BIN_DIR_USER/dcgm-exporter && chmod 755 $BIN_DIR_USER/dcgm-exporter

      if [ -f "$CONFIG_DIR_USER/dcgm_exporter.service" ]; then
        cp $CONFIG_DIR_USER/dcgm_exporter.service $CONFIG_DIR_USER/dcgm_exporter.service.backup
        echo "Backing up existing dcgm_exporter.service to '$CONFIG_DIR_USER/dcgm_exporter.service.backup'"
      fi

      curl -fsSL https://raw.githubusercontent.com/TryCarbonara/NodeInstallation/main/client/dcgm-exporter/dcgm_exporter-vector.service -o $CONFIG_DIR_USER/dcgm_exporter.service \
        && echo 'OPTIONS="--address='localhost:$dvalue' --collectors='$SYSCONFIG_DIR_USER/dcp-metrics-included.csv'"' | tee $SYSCONFIG_DIR_USER/dcgm_exporter > /dev/null
      
      curl -fsSL https://raw.githubusercontent.com/TryCarbonara/NodeInstallation/main/client/dcgm-exporter/default-counters.csv -o $SYSCONFIG_DIR_USER/default-counters.csv \
        && curl -fsSL https://raw.githubusercontent.com/TryCarbonara/NodeInstallation/main/client/dcgm-exporter/dcp-metrics-included.csv -o $SYSCONFIG_DIR_USER/dcp-metrics-included.csv
      
      systemctl --user daemon-reload \
        && systemctl --user restart dcgm_exporter \
        && systemctl --user enable dcgm_exporter
    fi

    echo -e "\n"
    echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    echo '@ **Step 2+:** Install SMI GPU exporter tool, for host **GPU (Nvidia)** power consumption data  @'
    echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"

    echo "Installing NVIDIA-SMI GPU Manager ..."
    VERSION=1.1.0
    curl -fsSL https://github.com/utkuozdemir/nvidia_gpu_exporter/releases/download/v${VERSION}/nvidia_gpu_exporter_${VERSION}_linux_x86_64.tar.gz -o $WORK_DIR/nvidia_gpu_exporter_${VERSION}_linux_x86_64.tar.gz
    tar -xvzf $WORK_DIR/nvidia_gpu_exporter_${VERSION}_linux_x86_64.tar.gz && mv $WORK_DIR/nvidia_gpu_exporter $BIN_DIR_USER/nvidia_gpu_exporter && chmod 755 $BIN_DIR_USER/nvidia_gpu_exporter
    # nvidia_gpu_exporter --help

    if [ -f "$CONFIG_DIR_USER/nvidia_gpu_exporter.service" ]; then
      cp $CONFIG_DIR_USER/nvidia_gpu_exporter.service $CONFIG_DIR_USER/nvidia_gpu_exporter.service.backup
      echo "Backing up existing nvidia_gpu_exporter.service to '$CONFIG_DIR_USER/nvidia_gpu_exporter.service.backup'"
    fi

    curl -fsSL https://raw.githubusercontent.com/TryCarbonara/NodeInstallation/main/client/smi-gpu-exporter/nvidia_gpu_exporter-vector.service -o $CONFIG_DIR_USER/nvidia_gpu_exporter.service \
      && echo 'OPTIONS="--web.listen-address='localhost:$svalue'"' | tee $SYSCONFIG_DIR_USER/nvidia_gpu_exporter > /dev/null

    systemctl --user daemon-reload \
        && systemctl --user restart nvidia_gpu_exporter \
        && systemctl --user enable nvidia_gpu_exporter
  fi
}

setup_node() {
  echo "Installing Node Exporter ..."
  curl -fsSL https://github.com/prometheus/node_exporter/releases/download/v1.3.1/node_exporter-1.3.1.linux-amd64.tar.gz \
    | tar -zxvf - -C $BIN_DIR_USER --strip-components=1 node_exporter-1.3.1.linux-amd64/node_exporter \
    && chown carbonara:carbonara $BIN_DIR_USER/node_exporter

  if [ -f "$CONFIG_DIR_USER/node_exporter.service" ]; then
    cp $CONFIG_DIR_USER/node_exporter.service $CONFIG_DIR_USER/node_exporter.service.backup
    echo "Backing up existing node_exporter.service to '$CONFIG_DIR_USER/node_exporter.service.backup'"
  fi
  if [ -f "$SYSCONFIG_DIR_USER/node_exporter" ]; then
    cp $SYSCONFIG_DIR_USER/node_exporter $SYSCONFIG_DIR_USER/node_exporter.backup
    echo "Backing up existing node_exporter sysconfig to '$SYSCONFIG_DIR_USER/node_exporter.backup'"
  fi

  curl -fsSL https://raw.githubusercontent.com/TryCarbonara/NodeInstallation/main/client/node-exporter/node_exporter-vector.service -o $CONFIG_DIR_USER/node_exporter.service \
    && echo 'OPTIONS="--collector.uname --collector.processes --collector.systemd --collector.tcpstat --collector.cpu.info --collector.rapl --collector.systemd.enable-task-metrics --web.disable-exporter-metrics --collector.diskstats.ignored-devices=\"^(ram|loop|fd|nfs)\\d+$\" --collector.zfs --web.listen-address='localhost:$nvalue'"' | tee $SYSCONFIG_DIR_USER/node_exporter > /dev/null
  
  systemctl --user daemon-reload \
    && systemctl --user restart node_exporter \
    && systemctl --user enable node_exporter
}

setup_grafana_agent() {
  mkdir -p $LIB_DIR_USER/grafana-agent
  curl -fsSL https://client-installables-shared.s3.us-west-1.amazonaws.com/grafana-agent-x86_64-0_39_0 -o $BIN_DIR_USER/grafana-agent && chmod 755 $BIN_DIR_USER/grafana-agent
  if [ -f "$CONFIG_DIR_USER/grafana-agent.service" ]; then
    cp $CONFIG_DIR_USER/grafana-agent.service $CONFIG_DIR_USER/grafana-agent.service.backup
    echo "Backing up existing grafana-agent service unit file to '$SYSCONFIG_DIR_USERgrafana-agent.service.backup'"
  fi
  if [ -f "$SYSCONFIG_DIR_USER/grafana-agent.yaml" ]; then
    cp $SYSCONFIG_DIR_USER/grafana-agent.yaml $SYSCONFIG_DIR_USER/grafana-agent.yaml.backup
    echo "Backing up existing grafana-agent config yaml file to '$SYSCONFIG_DIR_USER/grafana-agent.yaml.backup'"
  fi
  if [ -f "$SYSCONFIG_DIR_USER/grafana-agent" ]; then
    cp $SYSCONFIG_DIR_USER/grafana-agent $SYSCONFIG_DIR_USER/grafana-agent.backup
    echo "Backing up existing grafana-agent sysconfig to '$SYSCONFIG_DIR_USER/grafana-agent.backup'"
  fi

  curl -fsSL https://raw.githubusercontent.com/TryCarbonara/NodeInstallation/main/client/grafana-agent/grafana-agent-vector.service -o $CONFIG_DIR_USER/grafana-agent.service \
    && curl -fsSL https://raw.githubusercontent.com/TryCarbonara/NodeInstallation/main/client/grafana-agent/agent-client-vector.yaml -o $SYSCONFIG_DIR_USER/grafana-agent.yaml \
    && curl -fsSL https://raw.githubusercontent.com/TryCarbonara/NodeInstallation/main/client/grafana-agent/sysconfig.grafana_agent-vector -o $SYSCONFIG_DIR_USER/grafana-agent

  ip_addr=$(curl -s ifconfig.me || hostname -I | cut -f1 -d' ')
  echo "INSTANCE=$ip_addr" | tee -a $SYSCONFIG_DIR_USER/grafana-agent > /dev/null
  echo "PROVIDER=vector" | tee -a $SYSCONFIG_DIR_USER/grafana-agent > /dev/null
  echo "HOSTNAME=$(hostname)" | tee -a $SYSCONFIG_DIR_USER/grafana-agent > /dev/null
  echo "REMOTE_ENDPOINT=vector.stage.trycarbonara.io/prometheus" | tee -a $SYSCONFIG_DIR_USER/grafana-agent > /dev/null
  echo "AUTH_UNAME=vector" | tee -a $SYSCONFIG_DIR_USER/grafana-agent > /dev/null
  echo "AUTH_PWD=vector" | tee -a $SYSCONFIG_DIR_USER/grafana-agent > /dev/null
  echo "NODE_PORT=9100" | tee -a $SYSCONFIG_DIR_USER/grafana-agent > /dev/null
  echo "IPMI_PORT=9290" | tee -a $SYSCONFIG_DIR_USER/grafana-agent > /dev/null
  echo "DCGM_PORT=9400" | tee -a $SYSCONFIG_DIR_USER/grafana-agent > /dev/null
  echo "SMI_PORT=9835" | tee -a $SYSCONFIG_DIR_USER/grafana-agent > /dev/null
  systemctl --user daemon-reload \
    && systemctl --user restart grafana-agent \
    && systemctl --user enable grafana-agent
}

main() {
  parse_params "$@"
  if [ "$kvalue" == true ] ; then
    check false
  else
    if [ -z "$uvalue" ] || [ -z "$pvalue" ] ; then
      echo "Username/Password (account), to connect to Carbonara Service, is required. Use '-h' flag to learn more." >&2
      exit 1
    fi

    if [ -z "$rvalue" ] ; then
      echo "Carbonara service endpoint and port is required. Use '-h' flag to learn more." >&2
      exit 1
    fi

    # checking if none of the agents are already running; or cannot move forward
    check true

    echo -e "\n"
    echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    echo "@  **Step 0:** Setting Carbonara Working Directory as '$WORK_DIR'   @"
    echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    setup_workdir

    echo -e "\n"
    echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    echo '@ **Step 1:** Install IPMI exporter tool, for host power consumption data  @'
    echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    setup_ipmi

    echo -e "\n"
    echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    echo '@ **Step 2:** Install DCGM exporter tool, for host **GPU (Nvidia)** power consumption data  @'
    echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    setup_gpu

    echo -e "\n"
    echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    echo '@   **Step 3:** Install node exporter tool, for host resource usage data   @'
    echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    setup_node

    echo -e "\n"
    echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    echo "@     **Step 4:** Install Grafana Agent, for enabling metrics push      @"
    echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    setup_grafana_agent

    export PATH="$HOME/.local/bin:$PATH"
    echo -e "\n"
    echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    echo "@            You are all set to start publishing metrics to Carbonara             @"
    echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    echo -e "Please make sure to whitelist (egress) endpoint=$rvalue:443, if applicable."
    echo Happy Carbonara !!
  fi
}

main "$@"
