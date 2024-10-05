# Deploying ThreatMatrix on K8S
## Scaling the scalable

'[Threat Matrix](https://github.com/khulnasoft/ThreatMatrix)' is a one-stop destination for all your threat intelligence 
needs. This application, itself was designed on the idea of scalability and provides docker configurations for the same.
What if, one needs to deploy it for their organisation, which actively performs threat intelligence, 
and need high performance application for the same?

### Prerequisites

1. Kubernetes cluster, a docker registry/repository access, PostgresSQL Server, with a Database `threat_matrix_db`.
2. `kubectl`, `docker` installed on a host.
3. Internet, some coffee and common sense 🙂

### Phase 2: Preparing deployment files and configuration
1. Clone [ThreatMatrix-k8s](https://github.com/khulnasoft/ThreatMatrix-k8s). Make sure to include the `--recurse-submodule` parameter in the command.
    ```bash
    git clone https://github.com/khulnasoft/ThreatMatrix-k8s --recurse-submodule
    ```
2. Authenticate your `docker` to be able to push Docker Repository/Registry that the deployment will be using.
3. Fetch Cluster credentials and configure `kubectl` to be able to execute K8S deployments. 
5. Run the following command with appropriate value for
    `<address_of_docker_registry>`:

    ```bash
    ./build-tag-push.sh <address_of_docker_registry>
    ```
7. To set your API Keys, make the desired changes in `kustomization.yaml`. Set **DB_HOST** to the IP of your PostgresSQL
   server. Also change the DB_USER and DB_PASSWORD accordingly. (Similar to 
   [Deployment Preparation](https://threatmatrix.readthedocs.io/en/latest/Installation.html#deployment-preparation)).  

### Phase 3: Deployment

1.  Run `kubectl apply -k .` to create ENV Variable secrets. After Secrets has been created, run `kubectl get secrets` 
    and copy the name of secret that begins with `env-app-secrets-`. Run the following command to place this value in 
    deployment. Replace the `env-app-secrets-xxxxxx` with the value you copied.
    Also, run `kubectl get nodes` and copy any one of the node name and place it in place of <node_name>.
    ```bash
    ./deploy.sh env-app-secrets-xxxxxx <node_name>
    ```
    
Voila!! To get the IP Address for reaching the app, run `kubectl get svc` and IP will be available for 
Load Balancer Service.

To create admin user, first get the list of pods with `kubectl get pods -l app=backend-webapp`.
Then run `kubectl exec -it <ANY_POD_NAME_FROM_PREVIOUS_COMMAND> -c uwsgi python manage.py createsuperuser`, 
and follow the instructions to create an admin. Login and Enjoy!
