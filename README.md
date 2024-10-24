# Kubernetes Cluster ⏻ powerd by k0s on LXD containers

<!-- Start Overview -->
## Overview

k0s is an open source, all-inclusive Kubernetes distribution, which is configured with all of the features needed to build a Kubernetes cluster and packaged as a single binary for ease of use. Due to its simple design, flexible deployment options and modest system requirements, k0s is well suited for

- Any cloud
- Bare metal
- Edge and IoT

k0s drastically reduces the complexity of installing and running a CNCF certified Kubernetes distribution. With k0s new clusters can be bootstrapped in minutes and developer friction is reduced to zero. This allows anyone with no special skills or expertise in Kubernetes to easily get started.

k0s is distributed as a single binary with zero host OS dependencies besides the host OS kernel. It works with any Linux without additional software packages or configuration. Any security vulnerabilities or performance issues can be fixed directly in the k0s distribution that makes it extremely straightforward to keep the clusters up-to-date and secure.
<!-- End Overview -->

<!-- Start Key Features -->
## Key Features

- Certified and 100% upstream Kubernetes
- Multiple installation methodsmd.
- Automatic lifecycle management with k0sctl: [upgrade](docs/upgrade.md), [backup and restore](docs/backup.md)
- Modest [system requirements](docs/system-requirements.md) (1 vCPU, 1 GB RAM)
- Available as a single binary with no [external runtime dependencies](https://docs.k0sproject.io/stable/) besides the kernel
- Flexible deployment options with [control plane isolation](https://docs.k0sproject.io/stable/) as default
- Scalable from a single node to large, [high-available](https://docs.k0sproject.io/stable/) clusters
- Supports custom [Container Network Interface (CNI)](https://docs.k0sproject.io/stable/) plugins (Kube-Router is the default, Calico is offered as a preconfigured alternative)
- Supports custom [Container Runtime Interface (CRI)](https://docs.k0sproject.io/stable/) plugins (containerd is the default)
- Supports all Kubernetes storage options with [Container Storage Interface (CSI)](docs/storage.md)
- Supports a variety of [datastore backends](https://docs.k0sproject.io/stable/): etcd (default for multi-node clusters), SQLite (default for single node clusters), MySQL, and PostgreSQL
- Supports x86-64, ARM64 and ARMv7
- Includes [Konnectivity service](https://docs.k0sproject.io/stable/), CoreDNS and Metrics Server
<!-- End Key Features -->

## Multi-node Installation using k0sctl

k0sctl is a command-line tool for bootstrapping and managing k0s clusters. k0sctl connects to the provided hosts using SSH and gathers information on the hosts, with which it forms a cluster by configuring the hosts, deploying k0s, and then connecting the k0s nodes together.

![k0sctl deployment](img/k0sctl_deployment.png)

With k0sctl, you can create multi-node clusters in a manner that is automatic and easily repeatable. This method is recommended for production cluster installation.

**Note**: The k0sctl install method is necessary for automatic upgrade.

## Prerequisites

1. LXD ( An open-source solution for managing virtual machines and system containers). 
For more information, refer to the [lxd documentation](https://canonical.com/lxd/) 
See the [installation instructions](https://documentation.ubuntu.com/lxd/en/stable-4.0/installing/) for your operating system.

2. k0sctl 
You can execute k0sctl on any system that supports the Go language. Pre-compiled k0sctl binaries are available on the [k0sctl releases page](https://github.com/k0sproject/k0sctl/releases).

**Note**: For target host prerequisites information, refer to the [k0s System Requirements](system-requirements.md).

## Generate ssh keys 

Replace "your_email@example.com" with your own email address.

```
ssh-keygen -t ed25519 -b 4096 -C "your_email@example.com" -f $HOME/.ssh/k8s_rsa
```

## Launch LXD instances (Linux Hosts) 

Create LXD profile

```
$ lxc profile create k8s
```

Update the `k8s-profile.yaml` public key and put the result in your lxd k8s profile

Replace the `<your_public_key>` with your own public key found in your `~/.ssh/k8s_rsa.pub` file.

```
$ lxc profile edit k8s < k8s-profile.yaml
```

Launch containers; limit them to 1 vCPU and 1 GiB of RAM for nodes:

```
$ lxc launch ubuntu:24.04 kmaster --config limits.cpu=1 --config limits.memory=2GiB --profile k8s

$ lxc launch ubuntu:24.04 kworker1 --config limits.cpu=1 --config limits.memory=1GiB --profile k8s

$ lxc launch ubuntu:24.04 kworker2 --config limits.cpu=1 --config limits.memory=1GiB --profile k8s
```

## Enable root ssh login

As the root user, edit the sshd_config file found in /etc/ssh/sshd_config change the `PubkeyAuthentication` option to yes.

```
$ lxc exec kmaster /bin/bash

$ vi /etc/ssh/sshd_config

PubkeyAuthentication yes

$ systemctl restart ssh

$ exit 
```

## View LXD instances
```
$ lxc list 

+----------+---------+---------------------+-----------------------------------------------+-----------+-----------+
|   NAME   |  STATE  |        IPV4         |                     IPV6                      |   TYPE    | SNAPSHOTS |
+----------+---------+---------------------+-----------------------------------------------+-----------+-----------+
| kmaster  | RUNNING | 10.112.4.131 (eth0) | fd42:e22c:4def:1878:216:3eff:fee0:fbf1 (eth0) | CONTAINER | 0         |
+----------+---------+---------------------+-----------------------------------------------+-----------+-----------+
| kworker1 | RUNNING | 10.112.4.137 (eth0) | fd42:e22c:4def:1878:216:3eff:fed2:e4e4 (eth0) | CONTAINER | 0         |
+----------+---------+---------------------+-----------------------------------------------+-----------+-----------+
| kworker2 | RUNNING | 10.112.4.236 (eth0) | fd42:e22c:4def:1878:216:3eff:fe26:d2a4 (eth0) | CONTAINER | 0         |
+----------+---------+---------------------+-----------------------------------------------+-----------+-----------+
```

## Install k0s

### 1. Install k0sctl tool

k0sctl is a single binary, download the desired version for your operating system and processor architecture from the  [k0sctl releases page](https://github.com/k0sproject/k0sctl/releases). Make the file executable and place it in a directory available in your `$PATH`.

```
sudo mv ~/Downloads/k0sctl-linux-amd64 /usr/local/bin/k0sctl

sudo chmod a+x /usr/local/bin/k0sctl
```

1. Edit the `k0sctl.yaml` file to configure the cluster.

```yaml
apiVersion: k0sctl.k0sproject.io/v1beta1
kind: Cluster
metadata:
  name: k0s-cluster
spec:
  hosts:
  - ssh:
      address: xx.xxx.x.xx # replace with the controller's IP address
      user: root
      port: 22
      keyPath: ~/.ssh/k8s_rsa.pub # replace with the path to your ssh public key
    role: controller
  - ssh:
      address: xx.xxx.x.xx # replace with the worker1's IP address
      user: root
      port: 22
      keyPath: ~/.ssh/k8s_rsa.pub # replace with the path to your ssh public key
    role: worker
  - ssh:
      address: xx.xxx.x.xx # replace with the worker2's IP address
      user: root
      port: 22
      keyPath: ~/.ssh/k8s_rsa.pub # replace with the path to your ssh public key
    role: worker 
```

2. Provide each host with a valid IP address that is reachable by k0sctl, and the connection details for an SSH connection.

 **Note**: Refer to the [k0sctl documentation](https://github.com/k0sproject/k0sctl#configuration-file-spec-fields) for k0sctl configuration specifications.

### 3. Deploy the cluster

If you are running a firewall, you must allow ports 6443 and 2222.

```shell
sudo ufw allow 6443
```

Or 

```shell
sudo firewall-cmd --permanent --add-port=6443/tcp

sudo firewall-cmd --permanent --add-port=22/tcp

sudo firewall-cmd --permanent --add-service=ssh

firewall-cmd --reload
```

Run `k0sctl apply` to perform the cluster deployment:

```shell
k0sctl apply --config k0sctl.yaml

cat ~/.cache/k0sctl/k0sctl.log
```

```shell
⠀⣿⣿⡇⠀⠀⢀⣴⣾⣿⠟⠁⢸⣿⣿⣿⣿⣿⣿⣿⡿⠛⠁⠀⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀█████████ █████████ ███
⠀⣿⣿⡇⣠⣶⣿⡿⠋⠀⠀⠀⢸⣿⡇⠀⠀⠀⣠⠀⠀⢀⣠⡆⢸⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀███          ███    ███
⠀⣿⣿⣿⣿⣟⠋⠀⠀⠀⠀⠀⢸⣿⡇⠀⢰⣾⣿⠀⠀⣿⣿⡇⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀███          ███    ███
⠀⣿⣿⡏⠻⣿⣷⣤⡀⠀⠀⠀⠸⠛⠁⠀⠸⠋⠁⠀⠀⣿⣿⡇⠈⠉⠉⠉⠉⠉⠉⠉⠉⢹⣿⣿⠀███          ███    ███
⠀⣿⣿⡇⠀⠀⠙⢿⣿⣦⣀⠀⠀⠀⣠⣶⣶⣶⣶⣶⣶⣿⣿⡇⢰⣶⣶⣶⣶⣶⣶⣶⣶⣾⣿⣿⠀█████████    ███    ██████████
k0sctl v0.19.1 Copyright 2023, k0sctl authors.
Anonymized telemetry of usage will be sent to the authors.
By continuing to use k0sctl you agree to these terms:
https://k0sproject.io/licenses/eula
INFO ==> Running phase: Set k0s version  
INFO Looking up latest stable k0s version         
INFO Using k0s version v1.31.1+k0s.1              
INFO ==> Running phase: Connect to hosts 
INFO [ssh] 10.112.4.131:22: connected             
INFO [ssh] 10.112.4.137:22: connected             
INFO [ssh] 10.112.4.236:22: connected             
INFO ==> Running phase: Detect host operating systems 
INFO [ssh] 10.112.4.236:22: is running Ubuntu 24.04.1 LTS 
INFO [ssh] 10.112.4.131:22: is running Ubuntu 24.04.1 LTS 
INFO [ssh] 10.112.4.137:22: is running Ubuntu 24.04.1 LTS 
INFO ==> Running phase: Acquire exclusive host lock 
INFO ==> Running phase: Prepare hosts    
INFO ==> Running phase: Gather host facts 
INFO [ssh] 10.112.4.236:22: using kworker2 as hostname 
INFO [ssh] 10.112.4.131:22: using kmaster as hostname 
INFO [ssh] 10.112.4.137:22: using kworker1 as hostname 
INFO [ssh] 10.112.4.236:22: discovered eth0 as private interface 
INFO [ssh] 10.112.4.137:22: discovered eth0 as private interface 
INFO [ssh] 10.112.4.131:22: discovered eth0 as private interface 
INFO ==> Running phase: Validate hosts   
INFO ==> Running phase: Gather k0s facts 
INFO [ssh] 10.112.4.131:22: found existing configuration 
INFO [ssh] 10.112.4.131:22: is running k0s controller version v1.31.1+k0s.1 
INFO [ssh] 10.112.4.131:22: listing etcd members  
INFO [ssh] 10.112.4.137:22: is running k0s worker version v1.31.1+k0s.1 
INFO [ssh] 10.112.4.131:22: checking if worker kworker1 has joined 
INFO [ssh] 10.112.4.236:22: is running k0s worker version v1.31.1+k0s.1 
INFO [ssh] 10.112.4.131:22: checking if worker kworker2 has joined 
INFO ==> Running phase: Validate facts   
INFO [ssh] 10.112.4.131:22: validating configuration 
INFO ==> Running phase: Release exclusive host lock 
INFO ==> Running phase: Disconnect from hosts 
INFO ==> Finished in 8s                  
INFO k0s cluster version v1.31.1+k0s.1 is now installed 
INFO Tip: To access the cluster you can now fetch the admin kubeconfig using: 
INFO      k0sctl kubeconfig
```

### 4. Access the cluster

To access your k0s cluster, use k0sctl to generate a `kubeconfig` for the purpose.

```shell
k0sctl kubeconfig > kubeconfig
```

With the `kubeconfig`, you can access your cluster using kubectl.

## Install kubectl

```shell
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

sudo mv kubectl /usr/local/bin/kubectl

sudo chmod a+x /usr/local/bin/kubectl 
```

```shell
kubectl get pods --kubeconfig kubeconfig -A
```

```shell
NAMESPACE     NAME                              READY   STATUS    RESTARTS   AGE
kube-system   coredns-679c655b6f-2pjq7          1/1     Running   0          19m
kube-system   coredns-679c655b6f-j2pw5          1/1     Running   0          19m
kube-system   konnectivity-agent-94jct          1/1     Running   0          20m
kube-system   konnectivity-agent-vbc4d          1/1     Running   0          20m
kube-system   kube-proxy-658gw                  1/1     Running   0          20m
kube-system   kube-proxy-h8fl7                  1/1     Running   0          20m
kube-system   kube-router-6nbb4                 1/1     Running   0          20m
kube-system   kube-router-rp9cb                 1/1     Running   0          20m
kube-system   metrics-server-78c4ccbc7f-4zfg4   1/1     Running   0          20m
```

## Known limitations

* k0sctl does not perform any discovery of hosts, and thus it only operates on the hosts listed in the provided configuration.
* k0sctl can only add more nodes to the cluster. It cannot remove existing nodes.

