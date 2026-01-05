# Kubernetes on EC2 with AWS EBS CSI – End‑to‑End (Manual, kubeadm)

This document captures **all the steps you followed**, plus a few **important ones that were missing**, to build a Kubernetes cluster on EC2 and successfully use **AWS EBS CSI (gp3)** for persistent storage.

It is written so that **future-you** can recreate this setup without debugging again.

---

## 1. EC2 Nodes & Prerequisites

### Cluster layout

* 1 Control Plane
* 2 Worker Nodes
* Ubuntu 22.04 LTS
* containerd runtime

Verify nodes:

```bash
kubectl get nodes -o wide
```

Example:

```
ip-10-0-1-121   Ready    control-plane
ip-10-0-1-115   Ready    <none>
ip-10-0-1-54    Ready    <none>
```

---

## 2. kubeadm Initialization (Control Plane)

```bash
sudo kubeadm init --pod-network-cidr=192.168.0.0/16
```

Configure kubectl:

```bash
mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

Install Calico CNI:

```bash
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
```

Install AWS EBS CSI Driver (Helm)
Add repo:

```bash
helm repo add aws-ebs-csi-driver https://kubernetes-sigs.github.io/aws-ebs-csi-driver
helm repo update
```

Install driver:

```bash
helm install aws-ebs-csi-driver aws-ebs-csi-driver/aws-ebs-csi-driver \
  --namespace kube-system
```

Verify:

```bash
kubectl get pods -n kube-system | grep ebs
```

---

## 3. Join Worker Nodes

On control plane:

```bash
kubeadm token create --print-join-command
```

On each worker node:

```bash
sudo kubeadm join <CONTROL_PLANE_IP>:6443 \
  --token <TOKEN> \
  --discovery-token-ca-cert-hash sha256:<HASH>
```

Verify:

```bash
kubectl get nodes
```

---

## 4. iptables Forwarding Fix (IMPORTANT)

Without this, **CNI networking and CSI attach can fail**.

Run on **ALL nodes (control + workers)**:
Note: This is included in user script
```bash
sudo iptables -P FORWARD ACCEPT
sudo apt-get install -y iptables-persistent
sudo netfilter-persistent save
```
---

## 5. AWS Security Group (Critical)

Allow **all internal traffic between nodes**:

```hcl
resource "aws_security_group_rule" "allow_internal_all" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  self              = true
  security_group_id = aws_security_group.k8s_cluster_sg.id
}
```

Ensure UDP 53 (DNS):

```hcl
resource "aws_security_group_rule" "allow_internal_udp" {
  type              = "ingress"
  from_port         = 53
  to_port           = 53
  protocol          = "udp"
  self              = true
  security_group_id = aws_security_group.k8s_cluster_sg.id
}
```

---

## 6. Setup kubectl on Local Machine

Copy kubeconfig:

```bash
scp ubuntu@<CONTROL_PLANE_PUBLIC_IP>:/etc/kubernetes/admin.conf ~/.kube/config
```

Edit `~/.kube/config`:

* Replace server IP with **control plane public IP**
* Add:

```yaml
insecure-skip-tls-verify: true
```

---

## 7. ECR Image Pull (Temporary Secret Method)

Create token:

```bash
TOKEN=$(aws ecr get-login-password --region us-east-1)
```

Create secret:

```bash
kubectl delete secret ecr-secret --ignore-not-found
kubectl create secret docker-registry ecr-secret \
  --docker-server=880265510348.dkr.ecr.us-east-1.amazonaws.com \
  --docker-username=AWS \
  --docker-password="$TOKEN"
```

⚠️ Token expires ~12 hours (IAM role is the real fix).

---

## 8. Application Deployment with PVC

Apply:

```bash
kubectl apply -f storageclass.yaml
kubectl apply -f pvc.yaml
kubectl apply -f deployment.yaml
```

---

## 9. Verify EBS Persistence (Proof)

Exec into pod:

```bash
kubectl exec -it <pod-name> -- sh
```

Inside pod:

```sh
echo "EBS WORKS" > /app/data/ebs.txt
exit
```

Delete pod:

```bash
kubectl delete pod <pod-name>
```

Verify after recreation:

```bash
kubectl exec -it <new-pod> -- cat /app/data/ebs.txt
```

Expected:

```
EBS WORKS
```

---
