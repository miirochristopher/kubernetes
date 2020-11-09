# Create A Kubernetes Cluster Using SaltStack.

<img src="/images/saltkube.png" width="500" height="400" alt="logo"/>

### Generate CA and TLS certificates using CfSSL

Let's clone the git repository on the Master node and create CA & certificates on the `k8s-certs/` directory using **`CfSSL`** tools:

```bash
git clone https://github.com/miirochristopher/saltkube.git /srv/salt
ln -s /srv/salt/pillar /srv/pillar

wget -q --show-progress --https-only --timestamping \
   https://pkg.cfssl.org/R1.2/cfssl_linux-amd64 \
   https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64

chmod +x cfssl_linux-amd64 cfssljson_linux-amd64
sudo mv cfssl_linux-amd64 /usr/local/bin/cfssl
sudo mv cfssljson_linux-amd64 /usr/local/bin/cfssljson
```

#### Domain Names And CA Certificates. 

Because we generate our own CA and certificates for the cluster, 

You MUST put every **hostname** and **IPs** of the **Kubernetes Cluster** (master & workers) in the `certs/kubernetes-csr.json` (**`hosts`** field). 

You can also modify the `certs/*json` files to match your cluster-name / country. (optional)  

You can use **either public or private names**, but they must be registered somewhere (DNS provider, internal DNS server, `/etc/hosts` file) or use **IP records instead of names**.

```bash
cd /srv/salt/k8s-certs
cfssl gencert -initca ca-csr.json | cfssljson -bare ca

# !!!!!!!!!
# Don't forget to edit kubernetes-csr.json before this point !
# !!!!!!!!!

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kubernetes-csr.json | cfssljson -bare kubernetes

chown salt: /srv/salt/k8s-certs/ -R
```

After that, edit the `pillar/cluster_config.sls` to tweak your future Kubernetes cluster :

### Don't forget to change Master's Hostname & Tokens  using `pwgen` for example !

If you want to enable IPv6 on pod's side, you need to change `kubernetes.worker.networking.calico.ipv6.enable` to `true`.

### Cluster Deployment

The configuration is done to use the Salt-master as the Kubernetes master. 

You can have them as different nodes if needed but the `post_install/script.sh` require `kubectl` and access to the `pillar` files.

#### The Recommended Configuration is :

- one or three Kubernetes-master (Salt-master & minion)

- one or more Kubernetes-workers (Salt-minion)

The Minion's roles are matched with `Salt Grains` (kind of inventory), so you need to define theses grains on your servers :

If you want a small cluster, a master can be a worker too. 

```bash
# Kubernetes masters
cat << EOF > /etc/salt/grains
role: k8s-master
EOF

# Kubernetes workers
cat << EOF > /etc/salt/grains
role: k8s-worker
EOF

# Kubernetes master & workers
cat << EOF > /etc/salt/grains
role: 
  - k8s-master
  - k8s-worker
EOF

service salt-minion restart 
```

After that, you can apply your configuration with a (`highstate`) :

```bash
# Apply Kubernetes master configurations :
~ salt -G 'role:k8s-master' state.highstate 

~ kubectl get componentstatuses
NAME                 STATUS    MESSAGE              ERROR
scheduler            Healthy   ok
controller-manager   Healthy   ok
etcd-0               Healthy   {"health": "true"}
etcd-1               Healthy   {"health": "true"}
etcd-2               Healthy   {"health": "true"}

# Apply Kubernetes worker configurations :
~ salt -G 'role:k8s-worker' state.highstate

~ kubectl get nodes

# Deploy Calico and Add-ons :
~  /opt/kubernetes/post_install/setup.sh

~# kubectl get pod --all-namespaces

### Add nodes afterwards 

If you want add a node on your Kubernetes cluster, just add the new **Hostname**  and *IPs* on `kubernetes-csr.json` and run theses commands to regenerate your cluster certificates :

```bash
cd /srv/salt/k8s-certs

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -profile=kubernetes \
  kubernetes-csr.json | cfssljson -bare kubernetes

# Reload k8s components on Master and Workers.
salt -G 'role:k8s-master' state.highstate
salt -G 'role:k8s-worker' state.highstate
```

The `highstate` configure automatically new workers (if it match the k8s-worker role in Grains).

- Tested on Debian, Ubuntu and Fedora.
- You can easily upgrade software version on your cluster by changing values in `pillar/cluster_config.sls` and apply a `highstate`.
- This configuration use ECDSA certificates (you can switch to `rsa` in `certs/*.json`).
- You can change IPv4 IPPool, enable IPv6, change IPv6 IPPool, enable IPv6 NAT (for no-public networks), change BGP AS number, Enable IPinIP (to allow routes sharing between subnets).
- If you use `salt-ssh` or `salt-cloud` you can quickly scale new workers.

