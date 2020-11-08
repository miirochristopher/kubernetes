kubernetes:
  version: v1.19.1
  domain: cluster.local

  master:
    count: 1
    hostname: master.kubernetes.local
    ipaddr: 10.240.0.10   
    etcd:
      version: v3.3.25
    encryption-key: '0Wh+uekJUj3SzaKt+BcHUEJX/9Vo2PLGiCoIsND9GyY='

  pki:
    enable: false
    host: master.kubernetes.local
    wildcard: '*.kubernetes.local'

  worker:
    runtime:
      provider: docker
      docker:
        version: 19.03.13
        data-dir: /dockerFS
    networking:
      cni-version: v0.8.0
      provider: calico
      calico:
        version: v3.16.4
        cni-version: v3.16.4
        calicoctl-version: v3.16.4
        controller-version: v3.16.4
        as-number: 64512
        token: hu0daeHais3a--CHANGEME--hu0daeHais3a
        ipv4:
          range: 192.168.0.0/16
          nat: true
          ip-in-ip: true
        ipv6:
          enable: false
          nat: true
          interface: eth0
          range: fd80:24e2:f998:72d6::/64

  global:
    clusterIP-range: 10.32.0.0/16
    helm-version: v3.4.0
    dashboard-version: v2.0.4
    coredns-version: 1.8.0 
    admin-token: Haim8kay1rar--CHANGEME--Haim8kay11ra
    kubelet-token: ahT1eipae1wi--CHANGEME--ahT1eipa1e1w
    metallb: 
      enable: false
      version: v0.9.4
      protocol: layer2
      addresses: 10.100.0.0/24
    ingress-nginx:
      enable: false 
      version: v3.7.1
      service-type: LoadBalancer
    cert-manager:
      enable: false
      version: v1.0.3
