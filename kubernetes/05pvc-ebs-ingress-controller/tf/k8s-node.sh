#!/bin/bash
set -euxo pipefail

##################################
# B. Disable swap (Kubernetes req)
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
apt-get install -y containerd

mkdir -p /etc/containerd
containerd config default >/etc/containerd/config.toml

# IMPORTANT: systemd cgroup
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' \
  /etc/containerd/config.toml

systemctl restart containerd
systemctl enable containerd

##################################
# F. Install kubeadm, kubelet, kubectl
##################################
apt-get install -y apt-transport-https ca-certificates curl

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
# G. Install Helm (Package Manager)
##################################
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash


##################################
# Enable kubelet (won't start until kubeadm init/join)
##################################
systemctl enable kubelet

iptables -P FORWARD ACCEPT
apt-get update
apt-get install -y iptables-persistent
netfilter-persistent save
