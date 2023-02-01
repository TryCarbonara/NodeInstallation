Welcome to **Carbonara**. Carbonara requires certain tooling/exporters to help scrape and publish sensor & usage data
for reporting the most accurate carbon emission.
<br> This script will help configure the machine. The installation is compatible with Linux running on bare-metal.

**Note:**
* Carbonara uses rapl/ipmi tooling to fetch detailed system/process level power consumption metrics on bare-metal host specifically for compute/memory resources
* Carbonara uses cloud jewel methodology for storage and network utilization, which is loosely based on [Methodology | Cloud Carbon Footprint](https://www.cloudcarbonfootprint.org/docs/methodology/)
* Carbonara uses a combination of both the above methodologies to provide most accurate emission as the carbon footprint
* Carbonara uses OSS Tooling to provide transparency

# Before you begin
In order to register your machine with Carbonara and ensure that the required tooling is configured for making the data available:
* Docker ([Engine](https://helm.sh/docs/intro/install/)) installed
```sh
echo "Installing Docker Enginer ..."
sudo apt install -y docker.io
```

# **Step 0:** *Setup Carbonara context*

### WorkDir
```sh
sudo mkdir /carbonara
cd /carbonara
```
Download/Clone all the files in rhe repo: `https://github.com/TryCarbonara/NodeInstallation` manually or using
```sh
git clone https://github.com/TryCarbonara/NodeInstallation
```
Note: 
* Please use `sudo` to run all the commands

# **Step 1:** *Install hubblo/scaphendre tool, if doesn't exist*
### Note: Carbonara leverages `hubblo/scaphendre` tool to get process level power consumption using RAPL sensor
Ref: https://github.com/hubblo-org/scaphandre
```sh
sudo chmod +x scaphendre_install.sh
./scaphendre_install.sh
```

Validate using `curl localhost:8080/metrics`

# **Step 2:** *Install node exporter tool, if doesn't exist*
### Note: Carbonara leverages `node_exporter` to get node level usage data
Ref: https://github.com/prometheus/node_exporter
```sh
sudo chmod +x node_exporter_install.shv
./node_exporter_install.sh
```

Validate using `curl localhost:9100/metrics`

# **Step 3:** *Install process exporter tool, if doesn't exist*
### Note: Carbonara leverages `process_exporter` to get process level usage data
Ref: https://github.com/ncabatoff/process-exporter
```sh
sudo chmod +x process_exporter_install.shv
./process_exporter_install.sh
```

Validate using `curl localhost:9256/metrics`

# **Step 4:** *Install IPMI tool, if doesn't exist*
### Note: Carbonara leverages `ipmi_exporter` to get hardware level power consumption data
Ref: https://github.com/prometheus-community/ipmi_exporter
```sh
sudo chmod +x ipmi_exporter_install.shv
./ipmi_exporter_install.sh
```

Validate using `curl localhost:9290/metrics`

# **Step 5:** Post Installation
Carbonara provides managed monitoring service to help compute/visualize the energy and carbon vectors. Similar to OpenTelemetry, Carbonara's monitoring service uses pull based approach. The above ports are expected to be open and reachable by Carbonara service. In case of security/ttl, you need to provide security information for Carbonara to incorporate.

Once all the above ports are verified, here is some information you need to provide to register your node with Carbonara service:
* Node IP Address. Publically accessible endpoint
* Architecture; eg: amd64
* Instance Type, if any; eg: medium.x86. You can leave it blank if no type defined

```Carbonara will provide access to visualization, as separate user accounts, for every customer```

**Please feel free to reach out to the team on hello@trycarbonara.com or other preferrable communication means for any support required in installting the tooling and registering your node**
