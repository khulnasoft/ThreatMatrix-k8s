#!/bin/bash
set -euo pipefail

DOCKER_REPO="$1"
if [[ -z "$DOCKER_REPO" ]]; then
  echo "Error: Docker repo not specified."
  exit 1
fi

echo "###############"
echo "Fetching Latest Files from ThreatMatrix"
echo "###############"
cp ThreatMatrix/docker/entrypoints/uwsgi.sh .
cp ThreatMatrix/configuration/threat_matrix.ini .
cp ThreatMatrix/docker/Dockerfile .
cp ThreatMatrix/docker/Dockerfile_nginx ./dockerfile-nginx

echo "###############"
echo "Modifying Dockerfile for K8S Deployment"
echo "###############"

# Modify Dockerfile for Kubernetes deployment
sed -i -e 's:frontend/:ThreatMatrix/frontend/:g' \
       -e 's:COPY . :COPY ThreatMatrix/. :g' \
       -e 's:COPY docker/:COPY ThreatMatrix/docker/:g' \
       -e 's:requirements/:ThreatMatrix/requirements/:g' Dockerfile

# Append necessary configurations to Dockerfile
cat <<EOF >> Dockerfile
RUN mkdir -p /etc/uwsgi/sites && mv \${PYTHONPATH}/configuration/threat_matrix.ini /etc/uwsgi/sites/
COPY ./ThreatMatrix/configuration/* /opt/deploy/configuration/
EOF

# Modify dockerfile-nginx and append configurations
cat <<EOF >> dockerfile-nginx
COPY ThreatMatrix/configuration/nginx/http.conf /etc/nginx/conf.d/default.conf
COPY ThreatMatrix/configuration/nginx/errors.conf /etc/nginx/errors.conf
EXPOSE 80 443
EOF

echo "###############"
echo "Building, Tagging, and Pushing Images to Docker Registry: $DOCKER_REPO"
echo "###############"

# Build and push the main image
docker build --tag "$DOCKER_REPO/threatmatrix:latest" .
docker push "$DOCKER_REPO/threatmatrix:latest"

# Modify nginx config for K8S
sed -i -e 's/server uwsgi/server backend-webapp-service.default.svc.cluster.local/g' ThreatMatrix/configuration/nginx/http.conf

# Replace placeholders in additional Dockerfiles
sed -i -e "s/changeit/$DOCKER_REPO/g" ./dockerfile-celery-beat ./dockerfile-celery-worker ./dockerfile-nginx

# Build and push additional images
docker build --tag "$DOCKER_REPO/celery-beat:latest" -f dockerfile-celery-beat .
docker push "$DOCKER_REPO/celery-beat:latest"

docker build --tag "$DOCKER_REPO/celery-worker:latest" -f dockerfile-celery-worker .
docker push "$DOCKER_REPO/celery-worker:latest"

docker build --tag "$DOCKER_REPO/nginx-rp:latest" -f dockerfile-nginx .
docker push "$DOCKER_REPO/nginx-rp:latest"

docker build --tag "$DOCKER_REPO/rabbitmq:latest" -f dockerfile-rabbitmq .
docker push "$DOCKER_REPO/rabbitmq:latest"

echo "###############"
echo "Updating Docker Repo in Deployment Files"
echo "###############"

# Update Docker repo in YAML files
sed -i -e "s/<docker-repo>/$DOCKER_REPO/g" ./backend-webapp.yaml ./frontend-deployment.yaml ./rabbitmq-daemon.yaml

echo "Deployment process complete."
