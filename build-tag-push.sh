#!/bin/bash
set -e;
echo "###############"
echo "Fetching Latest files from ThreatMatrix"
echo "###############"
cp ThreatMatrix/docker/entrypoints/uwsgi.sh .
cp ThreatMatrix/configuration/threat_matrix.ini .
cp ThreatMatrix/docker/Dockerfile .
cp ThreatMatrix/docker/Dockerfile_nginx ./dockerfile-nginx
echo "###############"
echo "Modifying files for K8S Deployment"
echo "###############"
sed -i -e 's:frontend/:ThreatMatrix/frontend/:g' -e 's:COPY . :COPY ThreatMatrix/. :g' Dockerfile
sed -i -e 's:docker/:ThreatMatrix/docker/:g' -e 's:COPY . :COPY ThreatMatrix/. :g' Dockerfile
sed -i -e 's:requirements/:ThreatMatrix/requirements/:g' -e 's:COPY . :COPY ThreatMatrix/. :g' Dockerfile
{
echo "
RUN mkdir -p /etc/uwsgi/sites && mv \${PYTHONPATH}/configuration/threat_matrix.ini /etc/uwsgi/sites/"
echo "COPY ./ThreatMatrix/configuration/* /opt/deploy/configuration/"
} >> ./Dockerfile
{
echo "
COPY ThreatMatrix/configuration/nginx/http.conf /etc/nginx/conf.d/default.conf"
echo "COPY ThreatMatrix/configuration/nginx/errors.conf /etc/nginx/errors.conf"
echo "EXPOSE 80 443"
} >> ./dockerfile-nginx
echo "###############"
echo "Building, Tagging, and Pushing Images to Docker Registry: $1"
echo "###############"
docker build --tag "$1"/threatmatrix:latest .
docker push "$1"/threatmatrix:latest
sed -i -e 's/server uwsgi/server backend-webapp-service.default.svc.cluster.local/g' ThreatMatrix/configuration/nginx/http.conf
sed -i -e "s/changeit/$1/g" ./dockerfile-celery-beat ./dockerfile-celery-worker ./dockerfile-nginx
docker build --tag "$1"/celery-beat:latest -f dockerfile-celery-beat .
docker push "$1"/celery-beat:latest
docker build --tag "$1"/celery-worker:latest -f dockerfile-celery-worker .
docker push "$1"/celery-worker:latest
docker build --tag "$1"/nginx-rp:latest -f ./dockerfile-nginx .
docker push "$1"/nginx-rp:latest
docker build --tag "$1"/rabbitmq:latest -f dockerfile-rabbitmq .
docker push "$1"/rabbitmq:latest
echo "###############"
echo "Updating Docker Repo in deployment files"
echo "###############"
sed -i -e "s/<docker-repo>/$1/g" ./backend-webapp.yaml ./frontend-deployment.yaml ./rabbitmq-daemon.yaml
