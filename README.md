# learn-consul-cluster-peering
A repository to help learn how Consul's Cluster Peering works

# Description
This repository contains two Terraform codebases for a datacenter - `dc1` and `dc2`; each one contains a K8s cluster.
This repository is used to showcase how Consul Cluster Peering works by using the HashiCups demo app. The HashiCups app consists of the following microservices:

- nginx
- frontend
- public-api
- products-api
- postgres (db)
- payments

The app `products-api` consumes the `postgres` service to list the items for sale in the HashiCups app. These two services will be deployed in `dc2`, with the rest of the services deployed in `dc1`. The app `public-api` in `dc1` will consume data from the `products-api` in `dc2` via the Consul Cluster Peering link between the two datacenters.

# Sample Workflow for this Repository
Here is a sample workflow on using this repository. For more details, please visit [learn.hashicorp.com](https://learn.hashicorp.com) and look for the Consul Cluster Peering tutorial.

1. Deploy Kubernetes clusters

    ```shell-session

    terraform -chdir=dc1 init
    terraform -chdir=dc2 init

    terraform -chdir=dc1 apply
    terraform -chdir=dc2 apply
    aws eks --region $(terraform -chdir=dc1 output -raw region) update-kubeconfig --name $(terraform -chdir=dc1 output -raw cluster_name) --alias=dc1
    aws eks --region $(terraform -chdir=dc2 output -raw region) update-kubeconfig --name $(terraform -chdir=dc2 output -raw cluster_name) --alias=dc2
    ```

2. Deploy Consul with consul-k8s

    ```shell-session
    consul-k8s install -context=dc1 -config-file=k8s-yamls/consul-helm.yaml --set=global.datacenter=dc1
    consul-k8s install -context=dc2 -config-file=k8s-yamls/consul-helm.yaml --set=global.datacenter=dc2
    ```

3. Deploy workloads
  * Deploy HashiCups on first cluster

    ```shell-session
    for service in {frontend,nginx,public-api,payments,intentions-dc1}; do kubectl --context=dc1 apply -f hashicups-v1.0.2/$service.yaml; done
    ```

  * Deploy rest of app on second cluster

    ```shell-session
    for service in {products-api,postgres,intentions-dc2}; do kubectl --context=dc2 apply -f hashicups-v1.0.2/$service.yaml; done
    ```

4. Verify deployment
  * Check out deployed services in each datacenter

    ```shell-session
    kubectl --context=dc1 get svc
    kubectl --context=dc2 get svc
    kubectl --context=dc1 get pods
    kubectl --context=dc2 get pods
    kubectl --context=dc1 port-forward pods/consul-server-0 8501:8500 --namespace consul
    kubectl --context=dc2 port-forward pods/consul-server-0 8502:8500 --namespace consul
    ```

  * Open the HashiCups store at http://localhost:8080. Verify you cannot see any products because products-api is not available in dc1

    ```shell-session
    kubectl --context=dc1 port-forward deploy/nginx 8080:80
    ```

5. Peer Consul clusters
  * Create a peering token on dc1 and distribute it to dc2

    ```shell-session
    kubectl --context=dc1 apply -f k8s-yamls/acceptor-on-dc1-for-dc2.yaml
    kubectl --context=dc1 get peeringacceptors
    kubectl --context=dc1 get secrets
    kubectl --context=dc1 get secret peering-token-dc2 -o yaml | kubectl --context=dc2 apply -f -
    ```

  * Establish a connection between clusters and verify it

    ```shell-session
    kubectl --context=dc2 apply -f k8s-yamls/dialer-dc2.yaml
    curl http://127.0.0.1:8501/v1/peering/dc2
    ```

6. Export the products-api service and verify it

    ```shell-session
    kubectl --context=dc2 apply -f k8s-yamls/exportedsvc-products-api.yaml
    curl "localhost:8501/v1/health/connect/products-api?peer=dc2" | jq # or check the services in the dc1 Consul UI 
    ```

7. Modify the public-api to connect to dc2's products-api as upstream

    ```shell-session
    kubectl --context=dc1 apply -f k8s-yamls/public-api-peer.yaml
    ```

8. Verify buying a coffee in HashiCups now works

9. Remove exported service (optional)

    ```shell-session
    kubectl --context=dc2 delete -f k8s-yamls/exportedsvc-products-api.yaml
    ```

10. Remove cluster peering (optional)
    ```shell-session
    kubectl --context=dc2 delete -f k8s-yamls/dialer-dc2.yaml
    kubectl --context=dc1 delete -f k8s-yamls/acceptor-on-dc1-for-dc2.yaml
    ```

11. Destroy environment

    ```shell-session
    consul-k8s uninstall -context=dc1
    consul-k8s uninstall -context=dc2
    kubectl --context=dc1 get svc --namespace consul
    kubectl --context=dc2 get svc --namespace consul  
    # check for any SVC left in the last two commands before running terraform destroy
    terraform -chdir=dc1 destroy
    terraform -chdir=dc2 destroy
    ```

# Thanks

This repository has borrowed code from the following other repositories. Thank you!

- https://github.com/vanphan24/cluster-peering-demo
- https://github.com/hashicorp/learn-terraform-provision-aks-cluster
