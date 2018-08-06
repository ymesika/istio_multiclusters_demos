# Distributed Guestbook

In this demo we took IBM's [Guestbook example application](https://github.com/IBM/guestbook) and configured our Multi-Cluster so that the `Guestbook` and `Redis` microservices are running on one cluster and the `Analyzer` is running on the other. This demonstrates communication between the clusters as `Guestbook v2` is calling the `Analyzer` service on the remote cluster.

The communication between the clusters is going through a set of Ingress and Egress Gateways that both clusters have by deploying Istio to each one of them.

The Guestbook example application has been tested with the following topologies:
1. Two IBM Kubernetes Clusters (IKS-IKS) where their ingress gateways are publicly available.
1. One IBM Kubernetes Cluster and one IBM Cloud Private (IKS-ICP) where the ICP is not accessible from outside of the organization network but can access the IKS cluster and the Watson Tone Analyzer Service. We are [using strongSwan VPN tunnel](../strongSwan/README.md) initiated by the IKS to connect the two clusters.

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
1. If your second cluster is an ICP or any on-prem cluster you will need to connect between the private and public clusters with a VPN tunneling. We have [additional instructions](../strongSwan/README.md) for creating such connection using strongSwan VPN Helm charts deployed onto IKS and ICP clusters.

## Setup Watson Tone Analyzer
Watson Tone Analyzer detects the tone from the words that users enter into the Guestbook app. The tone is converted to the corresponding emoticons.

1. Use `bx target --cf` or `bx target -o ORG -s SPACE` to set the Cloud Foundry org and space where you want to provision the service.

2. Create Watson Tone Analyzer in your account.
    ```console
    ibmcloud service create tone_analyzer lite my-tone-analyzer-service
    ```
3. Create a service key for the service.
    ```console
    ibmcloud service key-create my-tone-analyzer-service myKey
    ```
 
4. Show the service key that you created and note the **password** and **username**.
      ```console
      ibmcloud service key-show my-tone-analyzer-service myKey
      ```
 
> Save the **username** and **password** for your `config.sh` file in the next step.

## Installing
1. Modify the `config.sh` file and set the following parameters:
    1. `CLUSTER_A` should hold the Kubeconfig context for the 1st cluster
    1. `CLUSTER_B` should hold the Kubeconfig context for the 2nd cluster
    1. `TONE_ANALYZER_USERNAME` and `TONE_ANALYZER_PASSWORD` should hold your credentials for the Watson Tone Analyzer service from previous step
    1. `CLUSTER_B_TYPE` should be set to `"ICP"` if the 2nd cluster is an ICP. Use any other value if the 2nd cluster is a public one.
    1. `MANUAL_INJECTION` will toggle whether to run a `istioctl inject` to inject the sidecar to the deployed app pods. The app is being deployed to the `default` namespace and it depends on whether the automatic injection label is applied to that namespace or not. The main reason for disabling the automatic injection is when having an IKS with VPN pods deployed to the default namespace. In this case it's not desired that the VPN pods will be auto-injected.
1. Make sure both clusters are accessible
1. Execute the installation script:
    ```sh
    ./install.sh
    ```
1. The script will pause after installing Istio on both clusters and wait for you to press any key. Before continuing, make sure all Istio pods are running on *both* clusters:
    ```sh
    kubectl get pods -n istio-system --context=<cluster_A_context>
    kubectl get pods -n istio-system --context=<cluster_B_context>
    ```
1. The script continues and the Guestbook web page URL will be printed at the end. You can open this URL in your browser but as the deployment of the app takes few seconds you may need to refresh to see all information for that app.

## Verifying
If the integration between the two clusters has been established you should see the Tone Analyzer service response added in the form of text emoticons to the Guestbook history.
1. Launch the Guestbook web page by opening in your browser the URL printed at the end of the installation
1. Type in the Guestbook text field a sentence (e.g. `I just love this demo`) and hit the submit button
1. The history text at the top should show the sentence you entered along with a text emoticon based on the result from the Analyzer service. E.g.:  
```I just love this demo : Joy (✿◠‿◠)```
