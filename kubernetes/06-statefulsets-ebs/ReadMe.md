

ssh -i go-ec2-ssh-key.pem ubuntu@44.200.20.85

ssh -i go-ec2-ssh-key.pem ubuntu@34.234.167.124
ssh -i go-ec2-ssh-key.pem ubuntu@44.200.34.206

scp -i go-ec2-ssh-key.pem ubuntu@44.200.20.85:~/.kube/config ./k8s-config


kubectl run mongo-client \
  --rm -it \
  --image=mongo:7-jammy \
  -- bash

mongosh mongodb://mongodb-0.mongodb:27017

show dbs
use test
db.foo.insertOne({ok: true})
db.foo.find()


kubectl apply -f task-service.yaml

kubectl get pods -l app=task-service
kubectl get svc task-service



