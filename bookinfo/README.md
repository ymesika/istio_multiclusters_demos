# Distributed Bookinfo

In this demo we took Istio's [Bookinfo sample application](https://istio.io/docs/guides/bookinfo/) and configured our Multi-Cluster so that the `Productpage` and `Ratings` microservices are running on one cluster and the `Details` and `Reviews v1/v2/v3` are running on the other. This demonstrates a two way communication between the clusters as `Productpage`, for instance, is calling the `Reviews` service on the remote cluster while `Reviews v2/v3` themselves are calling the `Ratings` service from the first cluster.

The communication between the clusters is going through a set of Ingress and Egress Gateways that both clusters have by deploying Istio to each one of them.

The Bookinfo demo has been tested on the following topologies:
1. Two IBM Kubernetes Clusters (IKS-IKS) where their ingress gateways are publicly available.
1. One IBM Kubernetes Cluster and one IBM Cloud Private (IKS-ICP) where the ICP is not accessible from outside of the organization network but can access the IKS cluster. We are using Strongswan VPN tunnel initiated by the IKS to connect the two clusters.

## Prerequisites
1. Make sure the two target clusters are available as contexts in the Kubeconfig path.

    ```console
    export KUBECONFIG=[location_of_kubeconfig_for_A_context]:[location_of_kubeconfig_for_B_context]
    kubectl config get-contexts
    ```

    The kubeconfig context name for each one of the clusters will be used as configuration parameters to the installation scripts.

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
`strongSwan` is used to setup a IPSec VPN tunnel between clusters and share subnets of Kubernetes Pods and Services to remote clusters. As such, the deployment has two parts where in one the strongSwan is deployed on the public cluster as a VPN "server" and the other part installing the strongSwan as a "client" on the private cluster. Because the private cluster can access the public one but not vice versa, the "client" is the one that initiates the VPN tunnel.

Instructions below were tested with connecting an ICP cluster that has no public access to an IKS cluster (public).

### Install strongSwan on IKS
1. Set up Helm in IBM Cloud Kubernetes Service by following [these instructions](https://console.bluemix.net/docs/containers/cs_integrations.html#helm).
1. [Install strongSwan to public IKS Cluster using Helm chart](https://console.bluemix.net/docs/containers/cs_vpn.html#vpn).  
Example configuration parameters (from `config.yaml`) for the strongSwan Helm release on an IKS (the rest as default):
    - ipsec.auto: `add`
    - remote.subnet: `10.0.0.0/24`
1. Execute:
    ```sh
    kubectl get svc vpn-strongswan
    ```
    And write down the External IP of the service as you will need it when installing on ICP.

### Install strongSwan on ICP
1. [Complete the strongSwan IPSec VPN workarounds](https://www.ibm.com/support/knowledgecenter/SS2L37_2.1.0.3/cam_strongswan.html) for ICP.
1. Install the strongSwan from [the Catalog in the management console](https://www.ibm.com/support/knowledgecenter/SSBS6K_2.1.0.3/app_center/create_release.html).  
Example configuration parameters for the strongSwan Helm release on an ICP:
    - Chart name: `vpn`
    - Namespace: `default`
    - Operation at startup: `start`
	- Local subnets: `10.0.0.0/24`
    - Local id: `on-prem`
	- Remote gateway: _Public IP of IKS VPN service that you wrote down earlier_
	- Remote subnets: `172.30.0.0/16,172.21.0.0/16`
    - Remote id: `ibm-cloud`
	- Privileged authority for VPN pod: checked
1. Verify that ICP connected to IKS by running the following against the IKS:
    ```sh
    export STRONGSWAN_POD=$(kubectl get pod -l app=strongswan,release=vpn -o jsonpath='{ .items[0].metadata.name }')
    kubectl exec $STRONGSWAN_POD -- ipsec status
    ```
    If configured correctly the output of the command will list one established connection:
    ```sh
    Security Associations (1 up, 0 connecting):
    k8s-conn[10]: ESTABLISHED 65 minutes ago, 172.30.0.107[ibm-cloud]...10.113.87.181[on-prem]
    k8s-conn{34}:  INSTALLED, TUNNEL, reqid 9, ESP in UDP SPIs: c46d5d8d_i c688564f_o
    k8s-conn{34}:   172.21.0.0/16 172.30.0.0/16 === 10.0.0.0/24
    ```
