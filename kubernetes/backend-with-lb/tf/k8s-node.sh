#!/bin/bash
set -euxo pipefail

##################################
# A. Set hostname to AWS private DNS
##################################
PRIVATE_DNS=$(curl -s http://169.254.169.254/latest/meta-data/local-hostname)
hostnamectl set-hostname "$PRIVATE_DNS"

##################################
# B. Disable swap
##################################
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

##################################
# C. Enable kernel modules
##################################
modprobe overlay
modprobe br_netfilter

cat <<EOF >/etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

##################################
# D. Sysctl settings
##################################
cat <<EOF >/etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system

##################################
# E. Install containerd
##################################
apt-get update -y
apt-get install -y containerd socat conntrack

mkdir -p /etc/containerd
containerd config default >/etc/containerd/config.toml

sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' \
  /etc/containerd/config.toml

sed -i 's|sandbox_image = .*|sandbox_image = "registry.k8s.io/pause:3.9"|' \
  /etc/containerd/config.toml

systemctl restart containerd
systemctl enable containerd

##################################
# F. Install kubeadm, kubelet, kubectl
##################################
apt-get install -y apt-transport-https ca-certificates curl gnupg

mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key \
  | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /
EOF

apt-get update -y
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

##################################
# G. Enable kubelet (do NOT restart)
##################################
systemctl enable kubelet

##################################
# H. Enable external Cloud Provider (CCM)
##################################
mkdir -p /etc/systemd/system/kubelet.service.d

cat <<EOF >/etc/systemd/system/kubelet.service.d/20-cloud-provider.conf
[Service]
Environment="KUBELET_EXTRA_ARGS=--cloud-provider=external"
EOF


systemctl daemon-reload
systemctl restart kubelet


##################################
# I. Configuration Logic
##################################
if [[ $(hostname) == *"control-plane"* ]]; then
    echo "Configuring for Master node..."
    INTERNAL_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
    mkdir -p /etc/kubernetes
    cat <<EOF >/etc/kubernetes/kubeadm-config.yaml
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
kubernetesVersion: v1.29.0
controlPlaneEndpoint: "${INTERNAL_IP}:6443"
networking:
  podSubnet: "192.168.0.0/16"
apiServer:
  extraArgs:
    cloud-provider: external
controllerManager:
  extraArgs:
    cloud-provider: external
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: "${INTERNAL_IP}"
  bindPort: 6443
nodeRegistration:
  kubeletExtraArgs:
    cloud-provider: external
EOF
fi

systemctl daemon-reload
systemctl restart kubelet
