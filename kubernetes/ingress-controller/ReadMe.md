# Kubernetes Setup Commands

## Initialize Cluster
```bash
sudo kubeadm init --pod-network-cidr=192.168.0.0/16
mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
kubectl get nodes
```

## Install Calico Network Plugin
```bash
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/calico.yaml
kubectl get pods -n kube-system
```

## Join Worker Node
```bash
sudo kubeadm join 10.0.1.121:6443 --token jumouu.in1ssmrt8aug1qug \
	--discovery-token-ca-cert-hash sha256:82040a1003c510eb8d12a9a6053f1f8edad223be90ddcf0f4840acffbc1dae70
kubectl get nodes
```

## Install NGINX Ingress Controller
```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.11.3/deploy/static/provider/cloud/deploy.yaml
kubectl get pods -n ingress-nginx
```

## Setup Local kubectl Access
```bash
# Copy config from master to laptop
scp -i go-ec2-ssh-key.pem ubuntu@3.237.198.225:~/.kube/config ./k8s-config

# Edit k8s-config file
sudo nano ./k8s-config
# Add: insecure-skip-tls-verify: true
# Change the IP to your master node's public IP

# Set KUBECONFIG
export KUBECONFIG=$(pwd)/k8s-config
kubectl get nodes
```

## Create ECR Secret
```bash
# Get token
TOKEN=$(aws ecr get-login-password --region us-east-1)

# Create secret
kubectl create secret docker-registry ecr-secret \
  --docker-server=880265510348.dkr.ecr.us-east-1.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$TOKEN

kubectl get secret ecr-secret
```

## Deploy Application
```bash
kubectl apply -f ./deployment.yaml
kubectl get pods
kubectl get svc
kubectl get ingress
```

## Access Application (Port Forward)
```bash
kubectl port-forward -n ingress-nginx \
  svc/ingress-nginx-controller 8080:80

# In another terminal
curl http://localhost:8080/srv
```

TODO:
Persistent Volume with EBS
Persistent with MongoDB
Print Pod Name in response
TLS (HTTPS) with cert-manager
Replace port-forward with ALB