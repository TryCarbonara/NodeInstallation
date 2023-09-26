# pre-req
echo -e "\n"
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo "@     Setting Carbonara Working Directory as '/carbonara'     @"
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
mkdir -p /carbonara
chmod 777 -R /carbonara/
cd /carbonara
pkg install curl

# node-exporter
echo -e "\n"
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo '@   Install node exporter tool, for host resource usage data   @'
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo "Installing Node Exporter ..."
pkg install -y node_exporter
# sysrc prometheus_enable=YES
sysrc node_exporter_enable=YES
sed -i .backup 's/node_exporter_args:=""/node_exporter_args:="--collector.disable-defaults --collector.uname --collector.processes --collector.systemd --collector.tcpstat --collector.cpu.info --collector.rapl --collector.systemd.enable-task-metrics --web.disable-exporter-metrics"/g' /usr/local/etc/rc.d/node_exporter \
# sysrc node_exporter_args="--collector.disable-defaults --collector.uname --collector.processes --collector.systemd --collector.tcpstat --collector.cpu.info --collector.rapl --collector.systemd.enable-task-metrics --web.disable-exporter-metrics" \
      && service node_exporter restart

# FreeIPMI
echo -e "\n"
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo '@ Install IPMI exporter tool, for host power consumption data  @'
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
# enable ipmi if underlying h/w & kernel supports it
kldload ipmi || true
kldload ipmi_drv || true
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
fetch https://raw.githubusercontent.com/TryCarbonara/NodeInstallation/main/client/grafana-agent/agent-client-fc.yaml -o /etc/grafana-agent.yaml
ip_addr=$(curl -s ifconfig.me)
sed -i "s/\${INSTANCE}/$ip_addr/g" /etc/grafana-agent.yaml
# sed -i "s/\${PROVIDER}/$uvalue/g" /etc/grafana-agent.yaml
# sed -i "s/\${HOSTNAME}/$(hostname)/g" /etc/grafana-agent.yaml
# sed -i "s/\${REMOTE_ENDPOINT}/$rvalue/g" /etc/grafana-agent.yaml
# sed -i "s/\${REMOTE_PORT}/$tvalue/g" /etc/grafana-agent.yaml
# sed -i "s/\${AUTH_UNAME}/$uvalue/g" /etc/grafana-agent.yaml
# sed -i "s/\${AUTH_PWD}/$pvalue/g" /etc/grafana-agent.yaml
# sed -i "s/\${NODE_PORT}/$nvalue/g" /etc/grafana-agent.yaml
# sed -i "s/\${IPMI_PORT}/$ivalue/g" /etc/grafana-agent.yaml

sysrc grafana_agent_enable=YES
sysrc grafana_agent_config_file="/etc/grafana-agent.yaml"

echo -e "\n"
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo "@            You are all set to start publishing metrics to Carbonara             @"
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo -e "Please make sure to whitelist (egress) endpoint=$rvalue:$tvalue, if applicable."
echo "Happy Carbonara !!"
