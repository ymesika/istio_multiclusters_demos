# Distributed Bookinfo

In this demo we took Istio's [Bookinfo sample application](https://istio.io/docs/guides/bookinfo/) and configured our Multi-Cluster so that the `Productpage` and `Ratings` microservices are running on one cluster and the `Details` and `Reviews v1/v2/v3` are running on the other. This demonstrates a two way communication between the clusters as `Productpage`, for instance, is calling the `Reviews` service on the remote cluster while `Reviews v2/v3` themselves are calling the `Ratings` service from the first cluster.

The communication between the clusters is going through a set of Ingress and Egress Gateways that both clusters have by deploying Istio to each one of them.

The Bookinfo demo has been tested on the following topolgies:
1. Two IBM Kubernetes Clusters (IKS-IKS) where their ingress gateways are publicly available.
1. One IBM Kubernetes Cluster and one IBM Cloud Private (IKS-ICP) where the ICP is not accessible from outside of the organization network but can access the IKS cluster. We are using Strongswan VPN tunnel initiated by the IKS to connect the two clusters.

## Prerequisites
1. Make sure the two target clusters are available as contexes in the Kubeconfig path. The kubeconfig context name for each one of the clusters will be used as configuration parameters to the installation scripts.

    You can test that both clusters are accessible with the context name by executing the command:
    ```sh
    kubectl get nodes --context=<cluster_A_context>
    kubectl get nodes --context=<cluster_B_context>
    ```
1. Any public cluster should be able to assign a public IP to its Ingress Gateway. Ingress gatwayes are of type `LoadBalancer` when Istio is deployed on a public cluster.
1. If your second cluster is an ICP or any on-prem cluster you will need to connect between the private and public clusters with a VPN tunneling. We have instructions below for creating such connection using Strongswan VPN Helm charts deployed onto IKS and ICP clusters.

## Installing
1. Modify the `config.sh` file and set the following parameters:
    1. `CLUSTER_A` should hold the Kubeconfig context for the 1st cluster
    1. `CLUSTER_B` should hold the Kubeconfig context for the 2nd cluster
    1. `CLUSTER_B_TYPE` should be set to `"ICP"` if the 2nd cluster is an ICP. Use any other value if the 2nd cluster is a public one.
    1. `MANUAL_INJECTION` will toggle whether to run a `istioctl inject` to inject the sidecar to the deployed app pods. The app is being deployed to the `default` namespace and it depends on whether the automatic injection label is applied to that namespace or not. The main reason for disabling the automatic injection is when having an IKS with VPN pods deployed to the default namespace. In this case it's not desired that the VPN pods will be auto-injected.
1. Make sure both clusters are accessible
1. Execute the installation script:
    ```sh
    ./install.sh
    ```
1. The scripts will pause after installing Istio to both cluster and wait for you to press any key. Before continuing make sure all Istio pods are running on *both* clusters:
    ```sh
    kubectl get pods -n istio-system --context=<cluster_A_context>
    kubectl get pods -n istio-system --context=<cluster_B_context>
    ```
1. The script continues and the Bookinfo web page URL will be printed at the end. You can open this URL in your browser but as the deployment of the app takes few seconds you might need to refresh to see all information for that app.

## Connect Private and Public Clusters with Strongswan VPN
TBD