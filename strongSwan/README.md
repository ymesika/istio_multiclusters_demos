# Clusters VPN With strongSwan

As described in the [Bookinfo demo](../bookinfo/README.md), it can be deployed to a topology of one IBM Kubernetes Cluster and one IBM Cloud Private (IKS-ICP). As the ICP is not accessible from outside of the organization network but can access the IKS cluster, we are using strongSwan VPN tunnel initiated by the IKS to connect the two clusters.


## Connect Private and Public Clusters with Strongswan VPN
`strongSwan` is used to setup a IPSec VPN tunnel between clusters and share subnets of Kubernetes Pods and Services to remote clusters. As such, the deployment has two parts where in one the strongSwan is deployed on the public cluster as a VPN "server" and the other part installing the strongSwan as a "client" on the private cluster. Because the private cluster can access the public one but not vice versa, the "client" is the one that initiates the VPN tunnel.

Instructions below were tested with connecting an ICP cluster that has no public access to an IKS cluster (public).

### Install strongSwan on IKS
1. Set up Helm in IBM Cloud Kubernetes Service by following [these instructions](https://console.bluemix.net/docs/containers/cs_integrations.html#helm).
1. [Install strongSwan to public IKS Cluster using Helm chart](https://console.bluemix.net/docs/containers/cs_vpn.html#vpn).  
Example configuration parameters (from [`config.yaml`](config.yaml)) for the strongSwan Helm release on an IKS (the rest as default):
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
