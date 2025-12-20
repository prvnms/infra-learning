# Start minikube with 3 nodes
minikube start --nodes=3 --driver=docker

# check status
minikube status
minikube kubectl -- get nodes

# add registry
minikube addons enable registry

# verify it
minikube kubectl -- get pods -n kube-system | grep registry

# build docker image
docker build -t go-web:v1 .

# load the image to minikube
minikube image load go-web:v1

# list mini images
minikube image list

# create Deployment
minikube kubectl -- apply -f deployment.yaml

# verify pods
minikube kubectl -- get pods -o wide

# expose deployment as nodeport service
minikube kubectl -- expose deployment go-web --type=NodePort --port=8080

# check the service
minikube kubectl -- get svc

# Get the url
minikube service go-web --url


# Cleanup
minikube kubectl -- delete service go-web
minikube kubectl -- delete deployment go-web

## minikube cleanup
# stop cluster
minikube stop
# delete cluster completely
minikube delete



