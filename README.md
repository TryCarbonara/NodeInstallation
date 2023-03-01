# Carbonara Inc

Welcome to **Carbonara**! Carbonara is the carbon data platform empowering software engineers and IT teams deliver real climate outcomes. We are still in closed Beta. If you have feedback, please reach out to us via email or slack. \
Carbonara requires certain exporters to help scrape and publish sensor & usage data for reporting the most accurate carbon emission data. The installation is compatible with Linux running on bare-metal. These instructions will help configure your node(s) with Carbonara service.

---

## Before you begin

Carbonara uses a combination of 2 methodologies to provide the most accurate energy consumption and carbon emission scores.

* Carbonara uses tooling to fetch accurate host level power consumption metrics on bare-metal machines specifically for compute/memory resources, which is where IPMI helps. We use RAPL to provide process level granularity for the same, that is _optional_.
* Carbonara uses [cloud jewel methodology](https://www.etsy.com/codeascraft/cloud-jewels-estimating-kwh-in-the-cloud) for storage and network utilization, which requires node_exporter to provide the required metrics. Again process_exporter helps provide process level granularity for more operational purpose, which is _optional_.

In order to register your node with Carbonara and ensure that the required tooling is configured, please follow the below instructions.

_Note_:

* Please use `sudo` to run all the commands
* Users are encouraged to leverage `systemd` for managing the binaries (exporter) for better reliability. Please let us know if need further assitance for the same
* For docker based installs, please refer -
  * Docker ([Engine](https://www.docker.com/)) installed

```sh
echo "Installing Docker Enginer ..."
sudo apt install -y docker.io
```

## **Step 1:** Install _IPMI exporter tool_, for host power consumption data

IPMI Exporter is supported by prometheus community, and provides different mediums to install and setup on the host machine. The exporter relies on tools from the [FreeIPMI](https://www.gnu.org/software/freeipmi/) suite for the actual IPMI implementation. The FreeIPMI tooling suite can be installed using:

```sh
# FreeIPMI
apt-get update && apt-get install freeipmi-tools -y --no-install-recommends && rm -rf /var/lib/apt/lists/*
```

The actual exporter can further be configured either using docker or binary. Here are the steps for binary installation:

```sh
# IPMI Exporter
wget https://github.com/prometheus-community/ipmi_exporter/releases/download/v1.6.1/ipmi_exporter-1.6.1.linux-amd64.tar.gz
tar xfvz ipmi_exporter-1.6.1.linux-amd64.tar.gz
rm ipmi_exporter-1.6.1.linux-amd64.tar.gz
./ipmi_exporter-1.6.1.linux-amd64/ipmi_exporter --config.file=ipmi_local.yml &
# Please use the shared ipmi config file: https://raw.githubusercontent.com/TryCarbonara/NodeInstallation/main/ipmi_local.yml, let us know if there is a conflict with any existing configuration on the host.
```

For more details, please refer: <https://github.com/prometheus-community/ipmi_exporter>

## **Step 2:** Install _node exporter tool_, for host resource usage data

Prometheus exporter for hardware and OS metrics exposed by *NIX kernels, written in Go with pluggable metric collectors.

```sh
# Configuring node_exporter to run using docker
docker run -d \
--net="host" \
--pid="host" \
-v "/:/host:ro,rslave" \
quay.io/prometheus/node-exporter:latest \
--path.rootfs=/host --collector.processes \
--collector.systemd --collector.tcpstat \
--collector.diskstats.ignored-devices="^(ram|loop|fd)\\\\d+$"
# We recommend the above collectors configuration to get a complete coverage, please let us know if there is a conflict with any existing configuration on the host.

# Configuring node_exporter to run using tarball
wget https://github.com/prometheus/node_exporter/releases/download/v*/node_exporter-*.*-amd64.tar.gz
tar xvfz node_exporter-*.*-amd64.tar.gz
cd node_exporter-*.*-amd64
./node_exporter --collector.processes --collector.systemd --collector.tcpstat --collector.diskstats.ignored-devices="^(ram|loop|fd)\\\\d+$" &
```

_node_exporter_ can also be configured using direct binary or [ansible](https://github.com/cloudalchemy/ansible-node-exporter)
For more details, please refer: <https://github.com/prometheus/node_exporter>

---
>
> The below 2 steps are _OPTIONAL_ but _RECOMMENDED_ for process level granularity
>
---

## **Step 3:** Install _hubblo/scaphendre tool_, for process level power consumption data using RAPL sensor

Scaphandre is a monitoring agent, dedicated to energy consumption metrics.

Depending on your kernel version, you could need to modprobe the module intel_rapl or intel_rapl_common first:

`modprobe intel_rapl_common # or intel_rapl for kernels < 5`

```sh
# To quickly run scaphandre in your terminal you may use docker:
docker run -d -v /sys/class/powercap:/sys/class/powercap -v /proc:/proc -p 8080:8080 -ti hubblo/scaphandre prometheus

# for using downloaded binary (https://hubblo-org.github.io/scaphandre-documentation/tutorials/getting_started.html):
scaphandre stdout -t 15
```

_Note_:

* RAPL does support latest AMD Architectures. Also, With the Zen architecture, AMD replaced APM (Application Power Management) with RAPL (Running Average Power Limit). Source: https://arxiv.org/pdf/2108.00808.pdf, <https://developer.amd.com/wp-content/resources/55803_B0_PUB_0_91.pdf>
* RAPL has certain requirements to be supported on AMD, like Ubuntu 22.04 or higher or kernel > 5.11

For more details, please refer: <https://github.com/hubblo-org/scaphandre>

## **Step 4:** Install _process exporter tool_, for process level resource usage data

Prometheus exporter that mines /proc to report on selected processes.

```sh
# Configuring process_exporter to run
docker run -d --rm -p 9256:9256 --privileged -v /proc:/host/proc -v `pwd`/config:/config ncabatoff/process-exporter --procfs /host/proc -config.path /config/process.yml

# Prior to running this command, a dir /config with a config file `process.yml` is expected to exist
# Please use the shared process-exporter config file: https://raw.githubusercontent.com/TryCarbonara/NodeInstallation/main/process.yml, let us know if there is a conflict with any existing configuration on the host.
```

For more details, please refer: <https://github.com/ncabatoff/process-exporter>

## **Step 5:** Validate the generated metrics

Once the above tooling is configured successfully, please validate the generated metrics on configured ports.

* _IPMI-exporter_: Validate using `curl localhost:9290/metrics` or any other assigned port
* _node-exporter_: Validate using `curl localhost:9100/metrics` or any other assigned port
* _rapl-exporter_: Validate using `curl localhost:8080/metrics` or any other assigned port
* _process-exporter_: Validate using `curl localhost:9256/metrics` or any other assigned port

## **Step 6:** Post Installation

Carbonara provides managed monitoring service to help compute/visualize the energy and carbon vectors. Similar to OpenTelemetry, Carbonara's monitoring service uses pull based approach. The above ports are expected to be open and reachable by Carbonara service. In case of security/ttl, you need to provide security information for Carbonara to support.

Once all the above ports are verified, here is some information you need to provide to register your node with Carbonara service:

* Node IP Address. Publically accessible endpoint
* Architecture; eg: amd64
* Instance Type, if any; eg: medium.x86. or any other label/tag. You can leave it blank if no type defined

```Carbonara provides access to visualization, as separate user accounts, for every customer.```

**Please feel free to reach out to the team on hello@trycarbonara.com or using other preferrable communication means for any support required in configuring and registering your node**
