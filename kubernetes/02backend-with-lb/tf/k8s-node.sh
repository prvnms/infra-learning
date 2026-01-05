#!/bin/bash
set -euxo pipefail

# 1. Fetch AWS Metadata for Hostname and Instance ID
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
PRIVATE_DNS=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/local-hostname)
INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/instance-id)

# 2. Set Hostname to match AWS Private DNS (CRITICAL for CCM)
hostnamectl set-hostname "$PRIVATE_DNS"

# 3. Disable swap & standard K8s networking setup
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab
modprobe overlay && modprobe br_netfilter
cat <<EOF >/etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sysctl --system

# 4. Install containerd & K8s tools
apt-get update -y && apt-get install -y containerd socat conntrack curl
mkdir -p /etc/containerd
containerd config default >/etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl restart containerd

mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /" > /etc/apt/sources.list.d/kubernetes.list
apt-get update -y && apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

# 5. Pre-configure Kubelet for External Cloud Provider
mkdir -p /etc/systemd/system/kubelet.service.d
cat <<EOF > /etc/systemd/system/kubelet.service.d/20-aws.conf
[Service]
AZ=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
Environment="KUBELET_EXTRA_ARGS=--cloud-provider=external --provider-id=aws:///$AZ/$INSTANCE_ID"
EOF

systemctl daemon-reload
systemctl enable kubelet
systemctl restart kubelet