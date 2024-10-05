#!/bin/bash
set -e;
echo "###############"
echo "Updating secrets for K8S Deployment"
echo "###############"
sed -i -e "s/<PLACE_SECRETS>/$1/g" ./backend-webapp.yaml
echo "###############"
echo "Deploying RabbitMQ Daemonsets"
echo "###############"
kubectl apply -f ./rabbitmq-daemon.yaml
sleep 5;
echo "###############"
echo "Creating PersistentVolumeClaim to be shared by Pods"
echo "###############"
sed -i -e "s/<node>/$2/g" ./nginx-static-volume.yaml
kubectl apply -f ./nginx-static-volume.yaml
sleep 5;
echo "###############"
echo "Deploying Services and Loadbalancers"
echo "###############"
kubectl apply -f ./services.yaml
sleep 60;
echo "###############"
echo "Deploying Backend ReplicaSets (Celery beat, Celery Worker, UWSGI)"
echo "###############"
kubectl apply -f ./backend-webapp.yaml
sleep 5;
echo "###############"
echo "Deploying Frontend ReplicaSets (Nginx Reverse Proxy)"
echo "###############"
kubectl apply -f ./frontend-deployment.yaml
sleep 5;
echo "###############"
echo "Deployment Successful"
echo "###############"
EXTERNAL_IP=$(kubectl get services | grep lb-service | awk -F' ' '{print $4 " on port " $5}')
EXTERNAL_IP=$(echo $EXTERNAL_IP | awk -F':' '{print $1}')
echo "ThreatMatrix is now accessible at $EXTERNAL_IP"
