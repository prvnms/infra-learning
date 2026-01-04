# Kubernetes Complete Reference

## Cluster Setup
```bash
sudo kubeadm init --pod-network-cidr=192.168.0.0/16
mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
kubectl get nodes
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/calico.yaml
kubectl get pods -n kube-system
sudo kubeadm join 10.0.1.121:6443 --token jumouu.in1ssmrt8aug1qug \
	--discovery-token-ca-cert-hash sha256:82040a1003c510eb8d12a9a6053f1f8edad223be90ddcf0f4840acffbc1dae70
kubectl get nodes
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.11.3/deploy/static/provider/cloud/deploy.yaml
kubectl get pods -n ingress-nginx
```

## Local kubectl Access
```bash
scp -i go-ec2-ssh-key.pem ubuntu@3.237.198.225:~/.kube/config ./k8s-config
sudo nano ./k8s-config
# Add: insecure-skip-tls-verify: true
# Change the IP to master node's public IP
export KUBECONFIG=$(pwd)/k8s-config
kubectl get nodes
```

## Docker Build & Push to ECR
```bash
docker build -t go-web-file:v2 .
docker images | grep go-web-file
docker tag go-web-file:v2 880265510348.dkr.ecr.us-east-1.amazonaws.com/go-web-file:v2
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 880265510348.dkr.ecr.us-east-1.amazonaws.com
docker push 880265510348.dkr.ecr.us-east-1.amazonaws.com/go-web-file:v2
aws ecr describe-images --repository-name go-web-file --region us-east-1
```

## ECR Secret Creation
```bash
TOKEN=$(aws ecr get-login-password --region us-east-1)
kubectl create secret docker-registry ecr-secret \
  --docker-server=880265510348.dkr.ecr.us-east-1.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$TOKEN
kubectl get secret ecr-secret
kubectl describe secret ecr-secret
```

## Deploy Application
```bash
kubectl apply -f ./deployment.yaml
kubectl get pods
watch kubectl get pods
kubectl describe pod <pod-name>
kubectl logs <pod-name>
kubectl get svc
kubectl get ingress
kubectl describe ingress web-ingress
```

## Access Application
```bash
kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller 8080:80
```

## Useful Commands
```bash
kubectl get all
kubectl get all -n ingress-nginx
kubectl get pods -o wide
kubectl get nodes --show-labels
kubectl get events --sort-by=.metadata.creationTimestamp
```

## Debugging
```bash
kubectl describe pod <pod-name>
kubectl describe svc <service-name>
kubectl describe ingress <ingress-name>
kubectl logs <pod-name>
kubectl logs <pod-name> -f
kubectl logs <pod-name> --previous
kubectl exec -it <pod-name> -- sh
kubectl exec -it <pod-name> -- ls /app/data
kubectl port-forward pod/<pod-name> 8080:8080
```

## Editing
```bash
kubectl edit deployment go-web-file
kubectl edit svc go-web-file-svc
kubectl scale deployment go-web-file --replicas=5
```

## Deleting
```bash
kubectl delete pod <pod-name>
kubectl delete deployment <deployment-name>
kubectl delete svc <service-name>
kubectl delete ingress <ingress-name>
kubectl delete -f deployment.yaml
kubectl delete pod <pod-name> --force --grace-period=0
```

## Restart/Rollout
```bash
kubectl rollout restart deployment go-web-file
kubectl rollout status deployment go-web-file
kubectl rollout history deployment go-web-file
kubectl rollout undo deployment go-web-file
```