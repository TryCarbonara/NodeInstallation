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
#%    -s : smi-gpu-exporter port | Default: 9835
#%    -e : process-exporter port | Default: 9256
#%    -c : cadvisor port | Default: 8080
#%    -u : Carbonara Username | Required
#%    -p : Carbonara Password | Required
#%    -r : Target Carbonara Remote Endpoint | Required
#%    -t : Target Carbonara Remote Port | Required
#%    -l : Local | Default: false
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

gvalue=false
lvalue=false
kvalue=false
vvalue=false

display_usage() { 
  echo "script usage: $(basename $0) [<flags>]" >&2
  echo "Flags:" >&2
  echo "  -h : Show usage" >&2
  echo "  -g : gpu-support | Default: false" >&2
  echo "  -n : node-exporter port | Default: 9100" >&2
  echo "  -i : ipmi-exporter port | Default: 9290" >&2
  echo "  -d : dcgm-exporter port | Default: 9400" >&2
  echo "  -s : smi-gpu-exporter port | Default: 9835" >&2
  echo "  -e : process-exporter port | Default: 9256" >&2
  echo "  -c : cadvisor port | Default: 8080" >&2
  echo "  -u : Carbonara Username | Required" >&2
  echo "  -p : Carbonara Password | Required" >&2
  echo "  -r : Target Carbonara Remote Endpoint | Required" >&2
  echo "  -t : Target Carbonara Remote Port | Required" >&2
  echo "  -l : Local | Default: false" >&2
  echo "  -v : Verbose | Default: false" >&2
  echo "  -k : Check Status | Default: false" >&2
}

parse_params() {
  while getopts 'hn:i:u:p:r:t:d:c:ks:e:glkv' OPTION; do
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
      e)
        evalue="$OPTARG"
        ;;
      c)
        cvalue="$OPTARG"
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

  if [ -z "$cvalue" ] ; then
    echo -e "cadvisor-exporter port is picking default value: 8080."
    cvalue=8080
  fi

  if [ -z "$evalue" ] ; then
    echo -e "process-exporter port is picking default value: 9256."
    evalue=9256
  fi

  if [ "$gvalue" == true ] ; then
    if [ -z "$dvalue" ] ; then
      echo -e "dcgm-exporter port is picking default value: 9400."
      dvalue=9400
    fi
    if [ -z "$svalue" ] ; then
      echo -e "smi-gpu-exporter port is picking default value: 9835."
      svalue=9835
    fi
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

  if [ "$gvalue" == true ] ; then
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

  echo -n "Checking port (cadvisor-exporter) ..."
  c_inuse=$((echo >/dev/tcp/localhost/$cvalue) &>/dev/null && echo "open" || echo "close")
  if [ "$c_inuse" == "open" ] ; then
    echo " Port in use" >&2
    if [ "$with_exit" == true ] ; then
      exit 1
    fi
  else
    echo " Port not is use" >&2
  fi
  CONTAINER_NAME='cadvisor'
  CID=$(docker ps -q -f status=running -f name=^/${CONTAINER_NAME}$)
  if [ ! "${CID}" ]; then
    echo "Cadvisor Exporter ... Failed"
  else
    echo "Cadvisor Exporter ... Succeeded"
  fi
  unset CID

  echo -n "Checking port (process-exporter) ..."
  e_inuse=$((echo >/dev/tcp/localhost/$evalue) &>/dev/null && echo "open" || echo "close")
  if [ "$e_inuse" == "open" ] ; then
    echo " Port in use" >&2
    if [ "$with_exit" == true ] ; then
      exit 1
    fi
  else
    echo " Port not is use" >&2
  fi
  CONTAINER_NAME='process_exporter'
  CID=$(docker ps -q -f status=running -f name=^/${CONTAINER_NAME}$)
  if [ ! "${CID}" ]; then
    echo "Process Exporter ... Failed"
  else
    echo "Process Exporter ... Succeeded"
  fi
  unset CID

  sd=$(systemctl status grafana-agent.service)
  if [ $? == 0 ]; then
    echo "Grafana Agent ... Succeeded"
  else
    echo "Grafana Agent ... Failed"
  fi
}

install_dependencies() {
  ($vvalue && apt-get update) || apt-get update > /dev/null
  ($vvalue && apt install -y net-tools) || apt install -y net-tools > /dev/null
  ($vvalue && apt-get install -y curl tar wget) || apt-get install -y curl tar wget > /dev/null
  # ($vvalue && apt install -y docker.io) || apt install -y docker.io > /dev/null
  mkdir -p /carbonara
  chmod 777 -R /carbonara/
  cd /carbonara
}

setup_ipmi() {
  # FreeIPMI
  # enable ipmi if underlying h/w & kernel supports it
  modprobe ipmi_devintf || true
  modprobe ipmi_si || true

  # check if ipmi is supported
  if ls /dev/ipmi* 1> /dev/null 2>&1; then
    echo "Installing FreeIPMI tool suite ..."
    ($vvalue && apt-get install freeipmi-tools -y --no-install-recommends --no-show-upgraded --no-upgrade) \
      || (apt-get install freeipmi-tools -y --no-install-recommends --no-show-upgraded --quiet --no-upgrade > /dev/null)

    echo "Installing IPMI Exporter ..."
    # IPMI Exporter
    curl -fsSL https://github.com/prometheus-community/ipmi_exporter/releases/download/v1.6.1/ipmi_exporter-1.6.1.linux-amd64.tar.gz \
    | tar -zxvf - -C /usr/local/bin --strip-components=1 ipmi_exporter-1.6.1.linux-amd64/ipmi_exporter \
    && chown root:root /usr/local/bin/ipmi_exporter

    if [ -f "/etc/systemd/system/ipmi_exporter.service" ]; then
      cp /etc/systemd/system/ipmi_exporter.service /etc/systemd/system/ipmi_exporter.service.backup
      echo "Backing up existing ipmi_exporter.service to '/etc/systemd/system/ipmi_exporter.service.backup'"
    fi
    if [ -f "/etc/sysconfig/ipmi_exporter" ]; then
      cp /etc/sysconfig/ipmi_exporter /etc/sysconfig/ipmi_exporter.backup
      echo "Backing up existing ipmi_exporter sysconfig to '/etc/sysconfig/ipmi_exporter.backup'"
    fi

    curl -fsSL https://raw.githubusercontent.com/TryCarbonara/NodeInstallation/main/client/ipmi-exporter/ipmi_exporter.service -o /etc/systemd/system/ipmi_exporter.service \
      && mkdir -p /etc/sysconfig \
      && echo 'OPTIONS="--config.file=/carbonara/ipmi_local.yml --web.listen-address='localhost:$ivalue'"' | tee /etc/sysconfig/ipmi_exporter > /dev/null \
      && curl -fsSL https://raw.githubusercontent.com/TryCarbonara/NodeInstallation/main/ipmi_local.yml -o /carbonara/ipmi_local.yml

    systemctl daemon-reload \
      && systemctl restart ipmi_exporter \
      && systemctl enable ipmi_exporter
  else
    echo "IPMI is not available."
    echo "Enabling RAPL module instead, for supported Architecture"
    modprobe intel_rapl_common || true
  fi
}

setup_dcgm() {
  echo "Current VGA devices:"
  lspci | grep -E 'VGA|Display ' | cut -d" " -f 1 | xargs -i lspci -v -s {}

  if [ -x "$(command -v nvidia-smi)" ] ; then
    sd=$(systemctl status dcgm_exporter.service)
    if [ $? == 0 ]; then
      echo "Skipping DCGM GPU Manager ..."
    else
      echo "Installing DCGM GPU Manager ..."
      # set up the CUDA repository GPG key
      # assuming x86_64 arch
      release=$(echo "ubuntu$(lsb_release -r | awk '{print $2}' | tr -d .)")
      ($vvalue && curl -fsSL https://developer.download.nvidia.com/compute/cuda/repos/$release/x86_64/cuda-keyring_1.0-1_all.deb -o cuda-keyring_1.0-1_all.deb \
        && dpkg -i cuda-keyring_1.0-1_all.deb \
        && add-apt-repository -y "deb https://developer.download.nvidia.com/compute/cuda/repos/$release/x86_64/ /") \
        || (curl -fsSL https://developer.download.nvidia.com/compute/cuda/repos/$release/x86_64/cuda-keyring_1.0-1_all.deb -o cuda-keyring_1.0-1_all.deb  > /dev/null \
        && dpkg -i cuda-keyring_1.0-1_all.deb > /dev/null \
        && add-apt-repository -y "deb https://developer.download.nvidia.com/compute/cuda/repos/$release/x86_64/ /"  > /dev/null)

      # install GPU Manager
      ($vvalue && apt-get update && apt install -y datacenter-gpu-manager --no-install-recommends --no-show-upgraded --no-upgrade) \
        || (apt-get update > /dev/null && apt install -y datacenter-gpu-manager --no-install-recommends --no-show-upgraded --quiet --no-upgrade > /dev/null)
      systemctl enable nvidia-dcgm \
        && systemctl restart nvidia-dcgm

      echo "Installing DCGM Exporter ..."
      # IPMI Exporter
      curl -fsSL https://raw.githubusercontent.com/TryCarbonara/NodeInstallation/main/client/dcgm-exporter/dcgm-exporter -o /usr/bin/dcgm-exporter && chmod 755 /usr/bin/dcgm-exporter

      if [ -f "/etc/systemd/system/dcgm_exporter.service" ]; then
        cp /etc/systemd/system/dcgm_exporter.service /etc/systemd/system/dcgm_exporter.service.backup
        echo "Backing up existing dcgm_exporter.service to '/etc/systemd/system/dcgm_exporter.service.backup'"
      fi

      curl -fsSL https://raw.githubusercontent.com/TryCarbonara/NodeInstallation/main/client/dcgm-exporter/dcgm_exporter.service -o /etc/systemd/system/dcgm_exporter.service \
        && mkdir -p /etc/sysconfig \
        && echo 'OPTIONS="--address='localhost:$dvalue'"' | tee /etc/sysconfig/dcgm_exporter > /dev/null \
        && mkdir -p /etc/dcgm-exporter \
        && curl -fsSL https://raw.githubusercontent.com/TryCarbonara/NodeInstallation/main/client/dcgm-exporter/default-counters.csv -o /etc/dcgm-exporter/default-counters.csv \
        && curl -fsSL https://raw.githubusercontent.com/TryCarbonara/NodeInstallation/main/client/dcgm-exporter/dcp-metrics-included.csv -o /etc/dcgm-exporter/dcp-metrics-included.csv

      systemctl daemon-reload \
        && systemctl restart dcgm_exporter \
        && systemctl enable dcgm_exporter
    
    fi

    echo -e "\n"
    echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    echo '@ **Step 2+:** Install SMI GPU exporter tool, for host **GPU (Nvidia)** power consumption data  @'
    echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"

    echo "Installing NVIDIA-SMI GPU Manager ..."
    VERSION=1.1.0
    wget https://github.com/utkuozdemir/nvidia_gpu_exporter/releases/download/v${VERSION}/nvidia_gpu_exporter_${VERSION}_linux_x86_64.tar.gz
    tar -xvzf nvidia_gpu_exporter_${VERSION}_linux_x86_64.tar.gz
    mv nvidia_gpu_exporter /usr/bin
    # nvidia_gpu_exporter --help

    if [ -f "/etc/systemd/system/nvidia_gpu_exporter.service" ]; then
      cp /etc/systemd/system/nvidia_gpu_exporter.service /etc/systemd/system/nvidia_gpu_exporter.service.backup
      echo "Backing up existing nvidia_gpu_exporter.service to '/etc/systemd/system/nvidia_gpu_exporter.service.backup'"
    fi

    curl -fsSL https://raw.githubusercontent.com/TryCarbonara/NodeInstallation/main/client/smi-gpu-exporter/nvidia_gpu_exporter.service -o /etc/systemd/system/nvidia_gpu_exporter.service \
      && mkdir -p /etc/sysconfig \
      && echo 'OPTIONS="--web.listen-address='localhost:$svalue'"' | tee /etc/sysconfig/nvidia_gpu_exporter > /dev/null \
      && systemctl daemon-reload \
      && systemctl enable --now nvidia_gpu_exporter \
      && systemctl restart nvidia_gpu_exporter
  fi
}

setup_node() {
  echo "Installing Node Exporter ..."
  curl -fsSL https://github.com/prometheus/node_exporter/releases/download/v1.3.1/node_exporter-1.3.1.linux-amd64.tar.gz \
    | tar -zxvf - -C /usr/local/bin --strip-components=1 node_exporter-1.3.1.linux-amd64/node_exporter \
    && chown root:root /usr/local/bin/node_exporter

  if [ -f "/etc/systemd/system/node_exporter.service" ]; then
    cp /etc/systemd/system/node_exporter.service /etc/systemd/system/node_exporter.service.backup
    echo "Backing up existing node_exporter.service to '/etc/systemd/system/node_exporter.service.backup'"
  fi
  if [ -f "/etc/sysconfig/node_exporter" ]; then
    cp /etc/sysconfig/node_exporter /etc/sysconfig/node_exporter.backup
    echo "Backing up existing node_exporter sysconfig to '/etc/sysconfig/node_exporter.backup'"
  fi

  curl -fsSL https://raw.githubusercontent.com/TryCarbonara/NodeInstallation/main/client/node-exporter/node_exporter.service -o /etc/systemd/system/node_exporter.service \
    && mkdir -p /etc/sysconfig \
    && echo 'OPTIONS="--collector.uname --collector.processes --collector.systemd --collector.tcpstat --collector.cpu.info --collector.rapl --collector.systemd.enable-task-metrics --web.disable-exporter-metrics --collector.diskstats.ignored-devices=\"^(ram|loop|fd|nfs)\\d+$\" --collector.zfs --web.listen-address='localhost:$nvalue'"' | tee /etc/sysconfig/node_exporter > /dev/null

  systemctl daemon-reload \
    && systemctl restart node_exporter \
    && systemctl enable node_exporter
}

setup_cadvisor() {
  wget https://nvidia.github.io/nvidia-docker/gpgkey --no-check-certificate
  apt-key add gpgkey
  distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
  curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | tee /etc/apt/sources.list.d/nvidia-docker.list
  ($vvalue && apt-get update && apt-get install -y nvidia-container-toolkit --no-install-recommends --no-show-upgraded --no-upgrade && systemctl daemon-reload && systemctl restart docker \
    && apt-get install -y python3-docker --no-install-recommends --no-show-upgraded --no-upgrade) \
    || (apt-get update > /dev/null && apt-get install -y nvidia-container-toolkit --no-install-recommends --no-show-upgraded --quiet --no-upgrade  > /dev/null \
    && systemctl daemon-reload > /dev/null && systemctl restart docker > /dev/null \
    && apt-get install -y python3-docker --no-install-recommends --no-show-upgraded --quiet --no-upgrade > /dev/null )
  
  VERSION=v0.36.0 # use the latest release version from https://github.com/google/cadvisor/releases
  docker run \
    --volume=/:/rootfs:ro \
    --volume=/var/run:/var/run:ro \
    --volume=/sys:/sys:ro \
    --volume=/var/lib/docker/:/var/lib/docker:ro \
    --volume=/dev/disk/:/dev/disk:ro \
    --publish=$cvalue:8080 \
    --detach=true \
    --name=cadvisor \
    --privileged \
    --device=/dev/kmsg \
    --restart=always \
    gcr.io/cadvisor/cadvisor:$VERSION
}

setup_process() {
  mkdir -p /carbonara/process_config \
      && curl -fsSL https://raw.githubusercontent.com/TryCarbonara/NodeInstallation/main/process.yml -o /carbonara/process_config/process.yml

  docker run \
    --publish=$evalue:9256 \
    --privileged \
    --detach=true \
    --volume=/proc:/host/proc \
    --volume=/carbonara/process_config:/config \
    --restart=always \
    --name=process_exporter \
    ncabatoff/process-exporter --procfs /host/proc -config.path /config/process.yml
}

setup_grafana_agent() {
  mkdir -p /etc/apt/keyrings/
  wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | tee /etc/apt/keyrings/grafana.gpg > /dev/null
  echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | tee /etc/apt/sources.list.d/grafana.list > /dev/null

  ($vvalue && apt-get update && apt-get install -y grafana-agent --no-install-recommends --no-show-upgraded --no-upgrade) \
    || (apt-get update > /dev/null && apt-get install -y grafana-agent --no-install-recommends --no-show-upgraded --quiet --no-upgrade > /dev/null)

  if [ -f "/etc/grafana-agent.yaml" ]; then
    cp /etc/grafana-agent.yaml /etc/grafana-agent.yaml.backup
    echo "Backing up existing grafana-agent config file to '/etc/grafana-agent.yaml.backup'"
  fi
  if [ -f "/etc/default/grafana-agent" ]; then
    cp /etc/default/grafana-agent /etc/default/grafana-agent.backup
    echo "Backing up existing grafana-agent sysconfig to '/etc/default/grafana-agent.backup'"
  fi

  curl -fsSL https://raw.githubusercontent.com/TryCarbonara/NodeInstallation/main/client/grafana-agent/agent-client.yaml -o /etc/grafana-agent.yaml && \
  curl -fsSL https://raw.githubusercontent.com/TryCarbonara/NodeInstallation/main/client/grafana-agent/sysconfig.grafana_agent -o /etc/default/grafana-agent

  ip_addr=$(curl -s ifconfig.me || hostname -I | cut -f1 -d' ')
  echo "INSTANCE=$ip_addr" | tee -a /etc/default/grafana-agent > /dev/null
  echo "PROVIDER=$uvalue" | tee -a /etc/default/grafana-agent > /dev/null
  echo "HOSTNAME=$(hostname)" | tee -a /etc/default/grafana-agent > /dev/null
  echo "REMOTE_ENDPOINT=$rvalue" | tee -a /etc/default/grafana-agent > /dev/null
  echo "REMOTE_PORT=$tvalue" | tee -a /etc/default/grafana-agent > /dev/null
  echo "AUTH_UNAME=$uvalue" | tee -a /etc/default/grafana-agent > /dev/null
  echo "AUTH_PWD=$pvalue" | tee -a /etc/default/grafana-agent > /dev/null
  echo "NODE_PORT=$nvalue" | tee -a /etc/default/grafana-agent > /dev/null
  echo "IPMI_PORT=$ivalue" | tee -a /etc/default/grafana-agent > /dev/null
  echo "DCGM_PORT=$dvalue" | tee -a /etc/default/grafana-agent > /dev/null
  echo "CADVISOR_PORT=$cvalue" | tee -a /etc/default/grafana-agent > /dev/null
  echo "SMI_PORT=$svalue" | tee -a /etc/default/grafana-agent > /dev/null
  echo "PROCESS_PORT=$evalue" | tee -a /etc/default/grafana-agent > /dev/null

  systemctl daemon-reload \
    && systemctl restart grafana-agent \
    && systemctl enable grafana-agent
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

    if [ -z "$rvalue" ] || [ -z "$tvalue" ] ; then
      echo "Carbonara service endpoint and port is required. Use '-h' flag to learn more." >&2
      exit 1
    fi

    # checking if none of the agents are already running; or cannot move forward
    check true

    echo -e "\n"
    echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    echo "@  **Step 0:** Installing pre-requisites for supporting Carbonara Setup and Setting Carbonara Working Directory as '/carbonara'  @"
    echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    install_dependencies

    echo -e "\n"
    echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    echo '@ **Step 1:** Install IPMI exporter tool, for host power consumption data  @'
    echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    setup_ipmi

    if [ "$gvalue" == true ] ; then
      echo -e "\n"
      echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
      echo '@ **Step 2:** Install DCGM exporter tool, for host **GPU (Nvidia)** power consumption data  @'
      echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
      setup_dcgm
    else
      echo "Skipping GPU ..."
    fi

    echo -e "\n"
    echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    echo '@   **Step 3:** Install node exporter tool, for host resource usage data   @'
    echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    setup_node

    echo -e "\n"
    echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    echo "@    **Step 4:** Install cAvisor exporter, for enabling container usage data     @"
    echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    setup_cadvisor

    echo -e "\n"
    echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    echo "@    **Step 5:** Install process exporter, for enabling container usage data     @"
    echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    setup_process

    echo -e "\n"
    echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    echo "@     **Step 6:** Install Grafana Agent, for enabling metrics push      @"
    echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    if [ $lvalue == false ] ; then
      setup_grafana_agent
    else
      echo "Skipping ..."
    fi

    echo -e "\n"
    echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    echo "@            You are all set to start publishing metrics to Carbonara             @"
    echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
    echo -e "Please make sure to whitelist (egress) endpoint=$rvalue:$tvalue, if applicable."
    echo Happy Carbonara !!
  fi
}

main "$@"
