sudo systemctl disable grafana-agent
sudo systemctl stop grafana-agent
sudo systemctl disable ipmi_exporter
sudo systemctl stop ipmi_exporter
sudo systemctl disable node_exporter
sudo systemctl stop node_exporter
sudo systemctl disable dcgm_exporter
sudo systemctl stop dcgm_exporter
sudo systemctl disable nvidia-dcgm
sudo systemctl stop nvidia-dcgm
sudo systemctl daemon-reload

# sudo systemctl status grafana-agent
# sudo systemctl status ipmi_exporter
# sudo systemctl status node_exporter
# sudo systemctl status dcgm_exporter
# sudo systemctl status nvidia_gpu_exporter

# sudo ./install_cli.sh -u equinix -p carbonara -r a5ebab6f283c8433393f3ba94e479056-38013799.us-west-1.elb.amazonaws.com -t 9090
