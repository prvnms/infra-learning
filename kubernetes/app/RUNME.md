# Do this After running terraform apply 

This document describes how to bootstrap a Kubernetes cluster on AWS EC2 using **kubeadm**, configure **remote kubectl access from a local laptop**, deploy a **Go application from Amazon ECR**, and expose it using **NodePort**.
---

## 1. Master Node Initialization

### Initialize the Control Plane

Run this on the **Master (Control Plane) VM**:

```bash
sudo kubeadm init \
  --apiserver-advertise-address=<INTERNAL_IP> \
  --pod-network-cidr=192.168.0.0/16
```

- `<INTERNAL_IP>` → Private IP of the control-plane EC2 instance
- `192.168.0.0/16` → Required by Calico CNI

---

### Configure kubectl for the ubuntu User

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

Verify:

```bash
kubectl get nodes
```

---

### Install Calico CNI

Calico enables pod-to-pod networking.

```bash
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/calico.yaml
```

Verify:

```bash
kubectl get pods -n kube-system
```

---

## 2. Configure Remote Access (Local Laptop)

This allows you to manage the cluster from your **local machine**.

### Copy kubeconfig from Master VM

```bash
scp -i your-ssh-key.pem ubuntu@<VM_PUBLIC_IP>:/home/ubuntu/.kube/config ~/.kube/config
```

---

### Fix API Server Access (Lab Only)

Since the certificate is issued for the **internal IP**, update kubeconfig to use the **public IP** and skip TLS verification.

```bash
kubectl config set-cluster kubernetes \
  --server=https://<VM_PUBLIC_IP>:6443
```

```bash
kubectl config set-cluster kubernetes \
  --insecure-skip-tls-verify=true
```

> ⚠️ This is **NOT recommended for production**.

---

### Security Group Requirement

Ensure AWS Security Group allows:

- **Inbound TCP 6443** from your **Laptop Public IP**

---

## 3. Deploy Worker Nodes

Run the **join command** shown at the end of `kubeadm init` on **each worker node**:

```bash
sudo kubeadm join <MASTER_IP>:6443 --token <token> \
    --discovery-token-ca-cert-hash sha256:<hash>
```

Verify from master or laptop:

```bash
kubectl get nodes -o wide
```

---

## 4. Deploy Go Application from Amazon ECR
---

### Authenticate Kubernetes with Amazon ECR

Create a Docker registry secret:

```bash
kubectl create secret docker-registry ecr-secret \
  --docker-server=<ECR_URI> \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password --region us-east-1)
```
- `<ECR_URI>` → URI of uploaded Repo in ECR

---

### Apply the Deployment

```bash
kubectl apply -f go-web-deployment.yaml
```

Verify:

```bash
kubectl get pods
```

---

## 5. Expose the Application (NodePort)

Expose the deployment:

```bash
kubectl expose deployment go-web --type=NodePort --port=8080
```

Get the assigned NodePort:

```bash
kubectl get svc go-web
```

Example output:

```text
NAME     TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)
go-web   NodePort   10.96.12.34     <none>        8080:30494/TCP
```

---

### Access the Application

Open in browser or curl:

```text
http://<WORKER_PUBLIC_IP>:<NODE_PORT>
```

## 6. Verification Commands

```bash
kubectl get nodes -o wide
kubectl get pods
kubectl get svc
```

---

## Notes

- NodePort works on **any worker node**, not just where the pod runs
- `kubectl port-forward` is often easier for development
- For production, use **Ingress + LoadBalancer (ALB)** instead of NodePort

---
